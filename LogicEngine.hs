{-# LANGUAGE ForeignFunctionInterface #-}
module LogicEngine where

import Foreign.C.Types

-- Exporta a função para o C usando a convenção 'ccall'
foreign export ccall calcular_dependencia :: CInt -> CInt -> CInt

-- Função pura: recebe (dependência_atual, escolha) -> retorna nova dependência
calcular_dependencia :: CInt -> CInt -> CInt
calcular_dependencia depAtual escolha
    | escolha == 3  = depAtual + 45  -- Concedeu acesso à Nex
    | escolha == 1  = max 0 (depAtual - 5)  -- Recusou a Nex
    | otherwise     = depAtual