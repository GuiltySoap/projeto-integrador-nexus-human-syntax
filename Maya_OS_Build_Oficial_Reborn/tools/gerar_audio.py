#!/usr/bin/env python3
"""Gerador do áudio autoral do HumaxOS: 9 efeitos sonoros (WAV) e 5 trilhas, uma por dia (OGG em laço).

Uso (a partir da raiz do projeto, onde fica o project.godot):
    python3 -I tools/gerar_audio.py              # escreve tudo em shared/assets/audio/
    python3 -I tools/gerar_audio.py sfx          # só os efeitos: boot, clique, abrir, fechar, notificacao, erro, glitch, sucesso, tecla
    python3 -I tools/gerar_audio.py bgm          # só as trilhas: bgm_dia_1.ogg ... bgm_dia_5.ogg
    python3 -I tools/gerar_audio.py --previa     # também grava espectrogramas em tests/_saida/previas/

Os nomes seguem o que o SistemaAudio procura (res://shared/assets/audio/<nome>.ogg|wav|mp3; bgm_dia_<N>). O áudio NÃO é
obrigatório: sem os arquivos o SistemaAudio continua gerando tudo de forma procedural.

Efeitos (WAV 16 bits mono 44,1 kHz, barramento SFX): curtos, com entrada e saída suaves (primeira e última amostra em zero),
picos entre -9 e -18 dBFS e nada de ataque áspero (os timbres duros passam por filtro passa-baixa).
Trilhas (OGG Vorbis estéreo 44,1 kHz, 48 s, barramento BGM): cada uma nasce de um buffer circular, então o fim emenda no começo
sem estalo (frequências com número inteiro de ciclos no laço, eventos que dão a volta, filtros e reverb por FFT circular):
    dia 1  tecnologia calma     pads abertos em Ré, notas esparsas, cintilação de dados.
    dia 2  vigilância discreta  pulso regular de 75 bpm, varreduras de "radar", harmonia fria.
    dia 3  anomalia             batimentos entre notas quase iguais, notas invertidas, falhas curtas e baixas.
    dia 4  isolamento           graves lentos, sinos distantes, vento, muito espaço.
    dia 5  colapso claustrofóbico  glissando infinito (Shepard–Risset), pressão grave, batimento cardíaco, falhas contidas.
Tudo é determinístico (sementes fixas). Requer numpy, Pillow (só para a prévia) e o ffmpeg com libvorbis no PATH.
Não faz parte do jogo nem da exportação (tools/* é excluído).
"""
import math
import os
import subprocess
import sys
import wave

import numpy as np

TAXA = 44100
DURACAO_LACO = 48.0
N = int(round(DURACAO_LACO * TAXA))
RAIZ = os.path.abspath(os.getcwd())
SAIDA = os.path.join(RAIZ, "shared", "assets", "audio")
PREVIAS = os.path.join(RAIZ, "tests", "_saida", "previas")
_T = np.arange(N, dtype=np.float64) / TAXA

_SEMITONS = {"C": -9, "D": -7, "E": -5, "F": -4, "G": -2, "A": 0, "B": 2}


# ------------------------------------------------------------------ utilidades gerais
def nota(nome):
    """'A4' -> 440 Hz; aceita sustenido (#) e bemol (b): 'F#4', 'Bb3'."""
    resto = nome[1:]
    alt = 0
    while resto and resto[0] in "#b":
        alt += 1 if resto[0] == "#" else -1
        resto = resto[1:]
    return 440.0 * 2.0 ** ((_SEMITONS[nome[0]] + alt + 12 * (int(resto) - 4)) / 12.0)


def tvec(n):
    return np.arange(n, dtype=np.float64) / TAXA


def ruido(n, semente):
    return np.random.default_rng(semente).standard_normal(n)


def normalizar(x):
    p = np.max(np.abs(x))
    return x / p if p > 0 else x


def filtro(x, baixo=None, alto=None, ordem=4):
    """Passa-faixa de fase zero por FFT (resposta de Butterworth). Em arrays circulares o resultado continua circular."""
    n = x.shape[0]
    X = np.fft.rfft(x, axis=0)
    f = np.fft.rfftfreq(n, 1.0 / TAXA)
    g = np.ones_like(f)
    if baixo:
        g = g / np.sqrt(1.0 + (baixo / np.maximum(f, 1e-3)) ** (2 * ordem))
    if alto:
        g = g / np.sqrt(1.0 + (f / alto) ** (2 * ordem))
    if x.ndim == 2:
        g = g[:, None]
    return np.fft.irfft(X * g, n, axis=0)


def rms(x):
    return float(np.sqrt(np.mean(np.square(x))))


def db(v):
    return 20.0 * math.log10(max(v, 1e-12))


# ------------------------------------------------------------------ efeitos sonoros
def tom(f0, f1, dur, forma="seno"):
    """Varredura exponencial de f0 a f1 Hz. forma: seno | triangulo | suave (quadrada arredondada)."""
    n = int(dur * TAXA)
    t = np.linspace(0.0, 1.0, n, endpoint=False)
    f = f0 * (f1 / f0) ** t
    fase = 2.0 * np.pi * np.cumsum(f) / TAXA
    fase -= fase[0]
    if forma == "triangulo":
        return (2.0 / np.pi) * np.arcsin(np.sin(fase))
    if forma == "suave":
        return np.tanh(2.2 * np.sin(fase)) / np.tanh(2.2)
    return np.sin(fase)


def env_ad(n, ataque, tau):
    """Ataque em seno² e queda exponencial (segundos)."""
    t = tvec(n)
    a = np.where(t < ataque, np.sin(0.5 * np.pi * np.clip(t / max(ataque, 1e-6), 0.0, 1.0)) ** 2, 1.0)
    return a * np.exp(-np.maximum(t - ataque, 0.0) / tau)


def fade(x, entrada_ms=1.5, saida_ms=10.0):
    """Entrada e saída em cosseno: começa e termina exatamente em zero (sem estalo)."""
    x = x.copy()
    n = len(x)
    ni = min(n // 2, int(entrada_ms * TAXA / 1000.0))
    no = min(n // 2, int(saida_ms * TAXA / 1000.0))
    if ni > 1:
        x[:ni] *= np.sin(0.5 * np.pi * np.arange(ni) / ni) ** 2
    if no > 1:
        x[-no:] *= np.cos(0.5 * np.pi * np.arange(no) / no) ** 2
    x[0] = 0.0
    x[-1] = 0.0
    return x


def pico_db(x, alvo_db):
    p = np.max(np.abs(x))
    return x * (10.0 ** (alvo_db / 20.0) / p) if p > 0 else x


def somar(buf, ev, inicio):
    i0 = int(round(inicio * TAXA))
    fim = min(len(buf), i0 + len(ev))
    if fim > i0:
        buf[i0:fim] += ev[: fim - i0]


# parciais do sino: (razão, amplitude, fator de queda); o timbre de "sininho de interface", sem ataque duro
_SINO = ((1.0, 1.0, 1.0), (2.0, 0.42, 0.55), (2.76, 0.2, 0.35), (5.4, 0.08, 0.2))


def sino(f, dur, tau, amp=1.0):
    n = int(dur * TAXA)
    t = tvec(n)
    y = np.zeros(n)
    for razao, a, q in _SINO:
        y += a * np.sin(2.0 * np.pi * f * razao * t) * np.exp(-t / (tau * q))
    return amp * y * np.minimum(1.0, t / 0.003)


def reverb_curta(x, rt60, mistura, semente):
    """Cauda curta (convolução linear por FFT) para os efeitos longos; devolve o mesmo comprimento de x."""
    n_ir = int(rt60 * 1.2 * TAXA)
    t = np.arange(n_ir) / TAXA
    ir = ruido(n_ir, semente) * np.exp(-6.9078 * t / rt60)
    ir = filtro(ir, 150.0, 5500.0, ordem=2)
    ir *= np.linspace(0.0, 1.0, n_ir) ** 0.25
    ir /= np.sqrt(np.sum(ir ** 2))
    m = len(x) + n_ir
    molhado = np.fft.irfft(np.fft.rfft(x, m) * np.fft.rfft(ir, m), m)[: len(x)]
    molhado *= rms(x) / max(rms(molhado), 1e-12)
    return x * (1.0 - mistura) + molhado * mistura


def sfx_clique():
    n = int(0.05 * TAXA)
    t = tvec(n)
    corpo = tom(1250.0, 760.0, 0.05) * env_ad(n, 0.0008, 0.010) * 0.55
    estalo = normalizar(filtro(ruido(n, 11), 1800.0, 7000.0)) * np.exp(-t / 0.0022) * 0.45
    return fade(pico_db(corpo + estalo, -12.0), 0.5, 12.0)


def sfx_tecla():
    n = int(0.03 * TAXA)
    t = tvec(n)
    corpo = tom(2100.0, 1500.0, 0.03) * env_ad(n, 0.0006, 0.006) * 0.5
    estalo = normalizar(filtro(ruido(n, 12), 3000.0, 9000.0)) * np.exp(-t / 0.0015) * 0.4
    return fade(pico_db(corpo + estalo, -18.0), 0.4, 8.0)


def _sopro(n, semente, baixo, alto, forca):
    t = tvec(n)
    return normalizar(filtro(ruido(n, semente), baixo, alto)) * np.sin(np.pi * np.clip(t / (n / TAXA), 0.0, 1.0)) ** 2 * forca


def sfx_abrir():
    n = int(0.19 * TAXA)
    y = (tom(380.0, 820.0, 0.19) * 0.5 + tom(570.0, 1230.0, 0.19) * 0.22) * env_ad(n, 0.022, 0.07)
    return fade(pico_db(y + _sopro(n, 13, 1500.0, 5200.0, 0.18), -12.0), 1.0, 25.0)


def sfx_fechar():
    n = int(0.16 * TAXA)
    y = (tom(760.0, 330.0, 0.16) * 0.5 + tom(1140.0, 495.0, 0.16) * 0.2) * env_ad(n, 0.012, 0.06)
    return fade(pico_db(y + _sopro(n, 16, 1200.0, 4200.0, 0.14), -12.5), 1.0, 25.0)


def sfx_notificacao():
    y = np.zeros(int(0.62 * TAXA))
    somar(y, sino(nota("G5"), 0.5, 0.17), 0.0)
    somar(y, sino(nota("D6"), 0.52, 0.21, 0.85), 0.115)
    return fade(pico_db(y, -10.0), 1.0, 60.0)


def sfx_sucesso():
    y = np.zeros(int(0.85 * TAXA))
    for i, (nm, amp, tau) in enumerate((("C5", 0.9, 0.15), ("E5", 0.9, 0.15), ("G5", 0.9, 0.15), ("C6", 1.0, 0.24))):
        somar(y, sino(nota(nm), 0.5 if i < 3 else 0.6, tau, amp), 0.085 * i)
    return fade(pico_db(y, -10.0), 1.0, 80.0)


def sfx_erro():
    y = np.zeros(int(0.34 * TAXA))
    for ini, f0, f1, d in ((0.0, 196.0, 175.0, 0.15), (0.185, 165.0, 139.0, 0.155)):
        m = int(d * TAXA)
        t = tvec(m)
        pulso = tom(f0, f1, d, "triangulo") * 0.7 + tom(2 * f0, 2 * f1, d) * 0.18
        env = np.minimum(1.0, t / 0.008) * np.cos(0.5 * np.pi * np.clip(t / d, 0.0, 1.0)) ** 0.8
        somar(y, pulso * env, ini)
    return fade(pico_db(filtro(y, 90.0, 1700.0), -10.5), 1.0, 30.0)


def sfx_glitch():
    y = np.zeros(int(0.24 * TAXA))
    # (início s, duração s, tipo, Hz): rajadas curtas de ruído filtrado e tons "quebrados" (4 bits, amostras repetidas)
    pecas = ((0.000, 0.022, "ruido", 2400), (0.034, 0.030, "tom", 1480), (0.078, 0.014, "ruido", 5200),
             (0.100, 0.040, "tom", 740), (0.152, 0.018, "ruido", 3000), (0.178, 0.050, "tom", 2960))
    for ini, d, tipo, f in pecas:
        m = int(d * TAXA)
        t = tvec(m)
        if tipo == "ruido":
            p = normalizar(filtro(ruido(m, f), f * 0.6, f * 1.4)) * 0.8
        else:
            p = tom(f, f * 0.97, d, "triangulo")
            p = np.repeat(p[::4], 4)[:m]
            p = np.round(p * 7.0) / 7.0
            p = p * (0.5 + 0.5 * np.tanh(3.0 * np.sin(2.0 * np.pi * 160.0 * t))) * 0.7
        somar(y, fade(p, 0.6, 2.0), ini)
    return fade(pico_db(filtro(y, 200.0, 9000.0), -12.0), 0.5, 15.0)


def sfx_boot():
    n = int(2.2 * TAXA)
    t = tvec(n)
    y = np.zeros(n)
    env = np.sin(0.5 * np.pi * np.clip(t / 0.45, 0.0, 1.0)) ** 2 * np.exp(-np.maximum(t - 0.7, 0.0) / 0.5)
    for nm, a in (("A2", 0.6), ("E3", 0.5), ("A3", 0.5), ("C#4", 0.35), ("E4", 0.3)):
        f = nota(nm)
        y += a * env * (np.sin(2 * np.pi * f * t) + 0.6 * np.sin(2 * np.pi * f * 1.002 * t) + 0.15 * np.sin(2 * np.pi * 2 * f * t))
    for ini, nm, amp, tau in ((0.18, "A4", 0.55, 0.35), (0.38, "E5", 0.5, 0.35), (0.58, "A5", 0.45, 0.55)):
        somar(y, sino(nota(nm), 1.2, tau, amp) * 0.7, ini)
    sopro = np.zeros(n)
    somar(sopro, _sopro(int(0.8 * TAXA), 15, 900.0, 6000.0, 0.08), 0.0)
    y = reverb_curta(y + sopro, 0.7, 0.28, 17)
    return fade(pico_db(y, -9.0), 2.0, 300.0)


EFEITOS = {
    "boot": sfx_boot, "clique": sfx_clique, "abrir": sfx_abrir, "fechar": sfx_fechar, "notificacao": sfx_notificacao,
    "erro": sfx_erro, "glitch": sfx_glitch, "sucesso": sfx_sucesso, "tecla": sfx_tecla,
}


def gravar_wav(x, caminho):
    pcm = np.clip(np.round(x * 32767.0), -32768, 32767).astype("<i2")
    with wave.open(caminho, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(TAXA)
        w.writeframes(pcm.tobytes())


# ------------------------------------------------------------------ trilhas (buffers circulares de 48 s)
def _q(f):
    """Quantiza a frequência para um número inteiro de ciclos em 48 s (erro < 0,011 Hz): a onda fecha o laço sem emenda."""
    return round(f * DURACAO_LACO) / DURACAO_LACO


def _seno(f, fase=0.0):
    return np.sin(2.0 * np.pi * _q(f) * _T + fase)


def _ciclos(c, fase=0.0):
    """Senoide lenta com c ciclos inteiros por laço (para modulações que precisam fechar)."""
    return np.sin(2.0 * np.pi * c * _T / DURACAO_LACO + fase)


def _janela(centro, meia):
    """Janela cos² circular: duas janelas vizinhas (centros a `meia` segundos) somam exatamente 1."""
    d = (_T - centro + DURACAO_LACO / 2.0) % DURACAO_LACO - DURACAO_LACO / 2.0
    return np.where(np.abs(d) < meia, np.cos(0.5 * np.pi * d / meia) ** 2, 0.0)


def _pan(x, p):
    th = (p + 1.0) * np.pi / 4.0
    return np.stack([x * math.cos(th), x * math.sin(th)], axis=1)


def _somar_circ(buf, ev, inicio):
    """Soma o evento em buf; o que passar do fim do laço volta para o começo."""
    i0 = int(round(inicio * TAXA)) % N
    n = len(ev)
    k = min(n, N - i0)
    buf[i0:i0 + k] += ev[:k]
    if k < n:
        buf[: n - k] += ev[k:]


def _voz(buf, idx, w, f, a, fase, pan):
    s = np.sin(2.0 * np.pi * _q(f) * _T[idx] + fase) * (w[idx] * a)
    th = (pan + 1.0) * np.pi / 4.0
    buf[idx, 0] += s * math.cos(th)
    buf[idx, 1] += s * math.sin(th)


def _pad(buf, rng, notas, centro, meia, harm=((1, 1.0), (2, 0.28), (3, 0.1)), detunes=(-0.13, 0.11), ganho=1.0, abertura=0.7):
    """Acorde sustentado entre janelas cos²: cada nota ganha harmônicos e duas vozes levemente desafinadas (efeito coro)."""
    w = _janela(centro, meia)
    idx = np.nonzero(w)[0]
    for nm in notas:
        f = nota(nm)
        for h, a in harm:
            for d in detunes:
                _voz(buf, idx, w, f * h + d * h, a * ganho / len(detunes), rng.uniform(0.0, 2.0 * np.pi), rng.uniform(-abertura, abertura))


def _pluck(f, dur, tau, brilho=0.35):
    n = int(dur * TAXA)
    t = tvec(n)
    y = np.sin(2 * np.pi * f * t) + brilho * np.sin(2 * np.pi * 2 * f * t) * np.exp(-t / (tau * 0.4)) + 0.12 * np.sin(2 * np.pi * 3 * f * t) * np.exp(-t / (tau * 0.25))
    return fade(y * np.minimum(1.0, t / 0.004) * np.exp(-t / tau), 0.0, 60.0)


def _reverb_circ(x, rt60, mistura, semente, amort=6000.0):
    """Reverb por convolução circular (FFT): a cauda de cada som dá a volta no laço, então não há emenda."""
    n_ir = int(min(rt60 * 1.25, 20.0) * TAXA)
    rng = np.random.default_rng(semente)
    t = np.arange(n_ir) / TAXA
    molhado = np.zeros_like(x)
    for c in range(2):
        ir = rng.standard_normal(n_ir) * np.exp(-6.9078 * t / rt60)
        ir = filtro(ir, 120.0, amort, ordem=2)
        rampa = int(0.012 * TAXA)
        ir[:rampa] *= np.linspace(0.0, 1.0, rampa)
        ir /= np.sqrt(np.sum(ir ** 2))
        H = np.fft.rfft(np.concatenate([ir, np.zeros(N - n_ir)]))
        molhado[:, c] = np.fft.irfft(np.fft.rfft(x[:, c]) * H, N)
    molhado *= rms(x) / max(rms(molhado), 1e-12)
    return x * (1.0 - mistura) + molhado * mistura


def _costura_calma(x):
    """Gira o buffer circular para que a emenda do laço caia no trecho mais calmo (menor atividade da derivada segunda).

    Como tudo é circular, girar não muda o som; só escolhe onde o arquivo começa e termina. Assim o ponto em que o
    codec Vorbis tem mais erro (as bordas do arquivo) fica num momento sem batida, falha ou ataque."""
    mono = x.mean(axis=1)
    d2 = np.abs(np.roll(mono, -1) - 2.0 * mono + np.roll(mono, 1))
    meia = int(0.04 * TAXA)
    ext = np.concatenate([d2[-meia:], d2, d2[:meia]])
    soma = np.concatenate([[0.0], np.cumsum(ext)])
    atividade = (soma[2 * meia + 1:] - soma[: -(2 * meia + 1)])[: len(d2)]
    passo = int(0.01 * TAXA)
    k = int(np.argmin(atividade[::passo])) * passo
    return np.roll(x, -k, axis=0)


def _estreitar(x, largura):
    m = (x[:, 0] + x[:, 1]) / 2.0
    s = (x[:, 0] - x[:, 1]) / 2.0 * largura
    return np.stack([m + s, m - s], axis=1)


def _masterizar(x, alvo_db, teto_db=-6.0):
    """Corta subsônicos e agudos ásperos, ajusta o volume (RMS acima de 100 Hz) e limita os picos suavemente em teto_db."""
    x = filtro(x, 28.0, 9500.0, ordem=2)
    x = x - x.mean(axis=0)
    ref = filtro(x, 100.0, None, ordem=2)
    x = x * (10.0 ** (alvo_db / 20.0) / rms(ref))
    teto = 10.0 ** (teto_db / 20.0)
    return teto * np.tanh(x / teto)


def _blip_quebrado(rng, f, dur, taxa_gate, amp):
    """Tom triangular "quebrado": 4–5 bits, amostras repetidas e porta rápida. Curto e baixo (falha controlada)."""
    m = int(dur * TAXA)
    t = tvec(m)
    p = tom(f, f * 0.985, dur, "triangulo")
    passo = int(rng.integers(3, 8))
    p = np.repeat(p[::passo], passo)[:m]
    bits = int(rng.integers(4, 6))
    p = np.round(p * (2 ** (bits - 1) - 1)) / (2 ** (bits - 1) - 1)
    p = p * (0.5 + 0.5 * np.tanh(3.0 * np.sin(2.0 * np.pi * taxa_gate * t)))
    return fade(p * amp, 1.0, 4.0)


def bgm_dia_1():
    """Dia 1 — tecnologia calma."""
    rng = np.random.default_rng(1001)
    x = np.zeros((N, 2))
    acordes = (
        ("D2", "A2", "E3", "A3", "D4", "F#4"),
        ("B1", "F#2", "D3", "A3", "C#4", "F#4"),
        ("G2", "D3", "B3", "D4", "F#4", "A4"),
        ("A1", "E2", "A2", "C#3", "E3", "B3"),
    )
    for i, ac in enumerate(acordes):
        _pad(x, rng, ac, 6.0 + 12.0 * i, 12.0, ganho=0.9)
    x *= (0.85 + 0.15 * _ciclos(2))[:, None]
    escalas = (("D5", "E5", "F#5", "A5", "B5"), ("B4", "D5", "F#5", "A5", "C#6"), ("G4", "B4", "D5", "F#5", "A5"), ("A4", "C#5", "E5", "B5"))
    for passo in range(96):
        t = passo * 0.5
        if rng.random() < 0.30:
            f = nota(escalas[int(t // 12.0) % 4][int(rng.integers(0, len(escalas[int(t // 12.0) % 4])))])
            ev = _pluck(f, 3.0, 0.7) * rng.uniform(0.07, 0.11)
            _somar_circ(x, _pan(ev, rng.uniform(-0.7, 0.7)), t)
    for _ in range(14):  # cintilação de dados: faíscas agudas, bem baixas
        f = nota(("E7", "B6", "F#7", "A6")[int(rng.integers(0, 4))])
        m = int(0.09 * TAXA)
        t = tvec(m)
        ev = fade(np.sin(2 * np.pi * f * t) * np.exp(-t / 0.014) * 0.018, 0.5, 20.0)
        _somar_circ(x, _pan(ev, rng.uniform(-0.8, 0.8)), rng.uniform(0.0, DURACAO_LACO - 0.2))
    for c in range(2):
        x[:, c] += filtro(ruido(N, 70 + c), 250.0, 4500.0) * 0.0035
    x = _reverb_circ(x, 3.2, 0.32, 11)
    return _masterizar(x, -22.0)


def bgm_dia_2():
    """Dia 2 — vigilância discreta."""
    rng = np.random.default_rng(2002)
    x = np.zeros((N, 2))
    acordes = (
        ("D2", "A2", "D3", "F3", "A3", "E4"),
        ("Bb1", "F2", "Bb2", "D3", "F3", "A3"),
        ("G2", "D3", "G3", "Bb3", "D4", "F4"),
        ("D2", "A2", "D3", "F3", "A3", "E4"),
        ("Bb1", "F2", "Bb2", "D3", "F3", "A3"),
        ("A1", "E2", "A2", "C#3", "E3", "G3"),
    )
    for i, ac in enumerate(acordes):
        _pad(x, rng, ac, 4.0 + 8.0 * i, 8.0, harm=((1, 1.0), (2, 0.18)), detunes=(-0.07, 0.07), ganho=0.9, abertura=0.4)
    tique_base = normalizar(filtro(ruido(int(0.04 * TAXA), 21), 2500.0, 7000.0))
    for k in range(60):  # pulso de 75 bpm: batida grave discreta + tique seco
        t = 0.8 * k
        acento = 1.0 if k % 4 == 0 else 0.0
        m = int(0.22 * TAXA)
        batida = tom(78.0, 46.0, 0.22) * env_ad(m, 0.004, 0.07) * (0.20 + 0.08 * acento)
        batida = batida + tom(156.0, 92.0, 0.22) * env_ad(m, 0.004, 0.05) * 0.06
        _somar_circ(x, np.stack([batida, batida], axis=1), t)
        tique = tique_base * np.exp(-tvec(len(tique_base)) / 0.005) * (0.05 + 0.05 * acento)
        _somar_circ(x, _pan(fade(tique, 0.3, 6.0), -0.15 if k % 2 == 0 else 0.15), t + 0.4)
    for t0 in (2.0, 14.0, 26.0, 38.0):  # varredura de radar: glissando suave que atravessa o campo estéreo
        d = 3.6
        m = int(d * TAXA)
        g = (tom(700.0, 3200.0, d) + 0.5 * tom(702.5, 3208.0, d)) * np.sin(np.pi * np.linspace(0, 1, m, endpoint=False)) ** 2 * 0.034
        th = np.linspace(0.12, 0.88, m) * np.pi / 2.0
        _somar_circ(x, np.stack([g * np.cos(th), g * np.sin(th)], axis=1), t0)
    for i, t0 in enumerate((6.0, 18.0, 30.0, 42.0)):  # ping
        m = int(1.5 * TAXA)
        p = fade(np.sin(2 * np.pi * 1760.0 * tvec(m)) * np.exp(-tvec(m) / 0.35) * 0.03, 2.0, 80.0)
        _somar_circ(x, _pan(p, 0.5 if i % 2 == 0 else -0.5), t0)
    for c in range(2):
        x[:, c] += filtro(ruido(N, 80 + c), 300.0, 3500.0) * 0.0025
    x = _reverb_circ(x, 2.2, 0.25, 12)
    return _masterizar(x, -22.0)


def bgm_dia_3():
    """Dia 3 — anomalia."""
    rng = np.random.default_rng(3003)
    x = np.zeros((N, 2))
    base = (("A1", 0.50, 0.00), ("A1", 0.40, 0.75), ("A2", 0.45, 0.00), ("A2", 0.30, 1.20), ("E3", 0.38, 0.00),
            ("E3", 0.30, -0.9), ("Bb3", 0.22, 0.00), ("Bb3", 0.16, 1.6), ("E4", 0.16, 0.0))
    for nm, a, d in base:
        x += _pan(_seno(nota(nm) + d, rng.uniform(0.0, 2.0 * np.pi)) * a, rng.uniform(-0.6, 0.6))
    f0, prof, c = _q(nota("E5")), 0.009, 6  # vibrato lento (±15 centésimos), periódico
    fase = 2.0 * np.pi * f0 * _T - 2.0 * np.pi * f0 * prof * (DURACAO_LACO / (2.0 * np.pi * c)) * np.cos(2.0 * np.pi * c * _T / DURACAO_LACO)
    x += _pan(np.sin(fase) * 0.05 * (0.55 + 0.45 * _ciclos(3)), 0.3)
    for t0, nm in ((5.0, "A5"), (17.0, "E5"), (29.0, "Bb5"), (40.0, "F5")):  # notas invertidas: nascem do silêncio e terminam secas
        s = _pluck(nota(nm), 3.2, 0.9)[::-1].copy()
        _somar_circ(x, _pan(fade(s, 5.0, 3.0) * 0.14, rng.uniform(-0.7, 0.7)), t0 - 3.2)
    ocupados = []
    while len(ocupados) < 9:  # falhas curtas e baixas, nunca coladas
        t0 = rng.uniform(1.0, DURACAO_LACO - 1.0)
        if all(abs(t0 - o) > 3.5 for o in ocupados):
            ocupados.append(t0)
    for t0 in sorted(ocupados):
        f = (415.3, 622.25, 932.3, 1244.5)[int(rng.integers(0, 4))]
        b = _blip_quebrado(rng, f, float(rng.uniform(0.04, 0.09)), float(rng.uniform(90.0, 200.0)), 0.07)
        _somar_circ(x, _pan(b, rng.uniform(-0.9, 0.9)), t0)
    for c2, ciclos_amp in enumerate((5, 4)):  # sussurro de banda estreita, difícil de localizar
        env = (0.5 + 0.5 * _ciclos(ciclos_amp, 1.3 * c2)) ** 2
        x[:, c2] += filtro(ruido(N, 90 + c2), 700.0, 2400.0) * env * 0.05
    x = _reverb_circ(x, 3.5, 0.30, 13)
    return _masterizar(x, -22.0)


def bgm_dia_4():
    """Dia 4 — isolamento."""
    rng = np.random.default_rng(4004)
    x = np.zeros((N, 2))
    for nm, d, a in (("E1", 0.0, 0.40), ("E1", 0.25, 0.40), ("E2", 0.0, 0.50), ("E2", 0.375, 0.34), ("B2", 0.0, 0.30), ("G3", 0.0, 0.14), ("G3", -0.5, 0.10)):
        x += _pan(_seno(nota(nm) + d, rng.uniform(0.0, 2.0 * np.pi)) * a, rng.uniform(-0.3, 0.3))
    for nm, a, ciclos_t in (("B5", 0.030, 5), ("F6", 0.020, 7)):  # fio agudo e frio, bem baixo
        trem = 0.55 + 0.45 * _ciclos(ciclos_t, rng.uniform(0.0, 6.0))
        x += _pan(_seno(nota(nm), rng.uniform(0.0, 6.0)) * a * trem, rng.uniform(-0.8, 0.8))
    for i, (t0, nm) in enumerate(((3.0, "E5"), (10.5, "B4"), (19.0, "F5"), (26.5, "E5"), (35.5, "Bb4"), (43.0, "B4"))):  # sinos distantes
        _somar_circ(x, _pan(sino(nota(nm), 6.0, 1.7, 0.16), -0.6 if i % 2 == 0 else 0.6), t0)
    vento = (0.5 + 0.5 * _ciclos(3, 0.6)) ** 2
    for c in range(2):
        x[:, c] += filtro(ruido(N, 100 + c), 80.0, 380.0) * vento * 0.20
        x[:, c] += filtro(ruido(N, 110 + c), 1400.0, 1900.0) * (0.5 + 0.5 * _ciclos(5, 2.0 * c)) * 0.025
    for t0 in (19.5, 42.8):  # baque distante no grave
        m = int(0.6 * TAXA)
        b = tom(62.0, 36.0, 0.6) * env_ad(m, 0.012, 0.16) * 0.22
        _somar_circ(x, np.stack([b, b], axis=1), t0)
    x = _reverb_circ(x, 6.0, 0.50, 14, amort=5000.0)
    return _masterizar(x, -24.0)


def bgm_dia_5():
    """Dia 5 — colapso claustrofóbico."""
    rng = np.random.default_rng(5005)
    M, m_ciclos = 7, 1904
    f0 = m_ciclos * math.log(2.0) / DURACAO_LACO  # f0·T/ln2 inteiro: o glissando que sobe uma oitava em 48 s fecha o laço
    u = _T / DURACAO_LACO
    esq = np.zeros(N)
    dir_ = np.zeros(N)
    for k in range(M):
        amp = np.sin(np.pi * (k + u) / M) ** 2
        fase = 2.0 * np.pi * f0 * (2.0 ** k) * (DURACAO_LACO / math.log(2.0)) * (2.0 ** u - 1.0)
        esq += amp * np.sin(fase)
        dir_ += amp * np.sin(fase + 0.9)  # mesmo deslocamento em todas as parciais, senão o laço não fecha
    x = np.stack([esq, dir_], axis=1) * 0.33
    am = (1.0 + 0.25 * _ciclos(96))
    for nm, d, a in (("A1", 0.0, 0.45), ("A1", 0.5, 0.40), ("A2", 0.0, 0.35), ("A2", 3.0, 0.30), ("E3", 0.0, 0.16), ("D1", 0.0, 0.30)):
        v = _seno(nota(nm) + d, rng.uniform(0.0, 2.0 * np.pi)) * a * am
        x += np.stack([v, v], axis=1)
    passo = DURACAO_LACO / 72.0  # 90 bpm
    envol = 0.75 + 0.25 * _ciclos(2, 0.4)
    for k in range(72):
        t = k * passo
        for atraso, forca in ((0.0, 0.45), (0.21, 0.30)):  # "lub-dub"
            m = int(0.18 * TAXA)
            b = (tom(72.0, 42.0, 0.18) + 0.35 * tom(144.0, 84.0, 0.18)) * env_ad(m, 0.004, 0.055) * forca * float(envol[int(((t + atraso) * TAXA)) % N])
            _somar_circ(x, np.stack([b, b], axis=1), t + atraso)
    ocupados = []
    while len(ocupados) < 14:
        t0 = rng.uniform(0.5, DURACAO_LACO - 0.5)
        if all(abs(t0 - o) > 1.8 for o in ocupados):
            ocupados.append(t0)
    for t0 in sorted(ocupados):  # falhas contidas: curtas, filtradas, sem pico
        f = (155.0, 233.0, 311.0, 466.0, 622.0, 932.0, 1245.0)[int(rng.integers(0, 7))]
        b = _blip_quebrado(rng, f, float(rng.uniform(0.025, 0.07)), float(rng.uniform(90.0, 220.0)), 0.10)
        _somar_circ(x, _pan(b, rng.uniform(-0.5, 0.5)), t0)
        if rng.random() < 0.4:
            mm = int(rng.uniform(0.01, 0.02) * TAXA)
            r = fade(normalizar(filtro(ruido(mm, int(t0 * 1000)), 1000.0, 5000.0)) * 0.05, 0.5, 3.0)
            _somar_circ(x, _pan(r, rng.uniform(-0.5, 0.5)), t0 + 0.03)
    respira = 0.4 + 0.6 * (0.5 + 0.5 * _ciclos(3))
    for c in range(2):
        x[:, c] += filtro(ruido(N, 120 + c), 100.0, 800.0) * respira * 0.12
    x = _estreitar(x, 0.35)
    x = _reverb_circ(x, 0.45, 0.18, 15)
    return _masterizar(x, -21.0)


TRILHAS = {"bgm_dia_1": bgm_dia_1, "bgm_dia_2": bgm_dia_2, "bgm_dia_3": bgm_dia_3, "bgm_dia_4": bgm_dia_4, "bgm_dia_5": bgm_dia_5}


def gravar_ogg(x, caminho, qualidade=3):
    cmd = ["ffmpeg", "-y", "-loglevel", "error", "-f", "f32le", "-ar", str(TAXA), "-ac", "2", "-i", "-",
           "-map_metadata", "-1", "-fflags", "+bitexact", "-flags:a", "+bitexact",
           "-c:a", "libvorbis", "-q:a", str(qualidade), "-ar", str(TAXA), caminho]
    subprocess.run(cmd, input=x.astype("<f4").tobytes(), check=True)


# ------------------------------------------------------------------ prévia (espectrogramas) e relatório
def espectrograma(mono, largura=1034, altura=96):
    """Matriz (altura x largura) em dB: frequência em escala logarítmica de 30 Hz a 12 kHz, tempo na horizontal."""
    n_fft = 2048
    hop = max(1, (len(mono) - n_fft) // (largura - 1))
    janela = np.hanning(n_fft)
    quadros = np.stack([mono[i * hop:i * hop + n_fft] * janela for i in range(largura)])
    mag = np.abs(np.fft.rfft(quadros, axis=1))
    freqs = np.fft.rfftfreq(n_fft, 1.0 / TAXA)
    bordas = np.geomspace(30.0, 12000.0, altura + 1)
    saida = np.zeros((altura, largura))
    for i in range(altura):
        sel = (freqs >= bordas[i]) & (freqs < bordas[i + 1])
        if not sel.any():
            sel = np.argmin(np.abs(freqs - bordas[i])) == np.arange(len(freqs))
        saida[i] = mag[:, sel].max(axis=1)
    return 20.0 * np.log10(np.maximum(saida, 1e-9))[::-1]


def gravar_previa(nome, mono):
    from PIL import Image, ImageDraw
    os.makedirs(PREVIAS, exist_ok=True)
    esp = espectrograma(mono)
    topo = esp.max()
    v = np.clip((esp - (topo - 70.0)) / 70.0, 0.0, 1.0)
    rgb = np.stack([255 * v ** 1.6, 200 * v ** 1.1, 255 * np.sqrt(v) * 0.9], axis=2).astype(np.uint8)
    img = Image.fromarray(rgb).resize((rgb.shape[1], rgb.shape[0] * 2), Image.NEAREST)
    ImageDraw.Draw(img).text((6, 4), nome, fill=(255, 255, 255))
    img.save(os.path.join(PREVIAS, "audio_%s.png" % nome))


def main():
    args = [a for a in sys.argv[1:]]
    previa = "--previa" in args
    escolha = [a for a in args if not a.startswith("--")]
    fazer_sfx = not escolha or "sfx" in escolha
    fazer_bgm = not escolha or "bgm" in escolha
    os.makedirs(SAIDA, exist_ok=True)
    if fazer_sfx:
        for nome, fn in EFEITOS.items():
            x = fn()
            gravar_wav(x, os.path.join(SAIDA, nome + ".wav"))
            print("%-14s %5.0f ms  pico %6.1f dBFS  rms %6.1f dBFS" % (nome + ".wav", 1000.0 * len(x) / TAXA, db(np.max(np.abs(x))), db(rms(x))))
    if fazer_bgm:
        for nome, fn in TRILHAS.items():
            x = _costura_calma(fn())
            gravar_ogg(x, os.path.join(SAIDA, nome + ".ogg"))
            print("%-14s %5.1f s   pico %6.1f dBFS  rms %6.1f dBFS  emenda |x[0]-x[-1]| %.5f  (passo típico %.5f)" % (
                nome + ".ogg", len(x) / TAXA, db(np.max(np.abs(x))), db(rms(x)), float(np.max(np.abs(x[0] - x[-1]))),
                float(np.median(np.abs(np.diff(x[:, 0]))))))
            if previa:
                gravar_previa(nome, x.mean(axis=1))


if __name__ == "__main__":
    main()
