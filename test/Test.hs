import Test.HUnit

import Lexer
import Parser

import LexerTest
import TestData

main = do
    test <- testLexer
    runTestTT test