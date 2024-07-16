module Main (main) where

import           AppState                         (AppStateIO, getWorkingDir,
                                                   initialState)
import           FileIO                           (makeDirectory)
import           Spigot.Builder.SpigotBuilder     (buildSpigot)

import           Control.Monad.Trans.Except       (runExceptT)
import           Control.Monad.Trans.State.Strict (runStateT)
import           System.Exit                      (exitFailure, exitSuccess)

makeNecessaryDirectories :: AppStateIO ()
makeNecessaryDirectories = do
    workingDir <- getWorkingDir

    makeDirectory workingDir $
        "Failed to make a directory '" ++ workingDir ++ "'"

program :: AppStateIO ()
program = do
    makeNecessaryDirectories
    buildSpigot

main :: IO ()
main = do
    initState   <- initialState
    (result, _) <- runStateT (runExceptT program) initState
    case result of
        Right () -> exitSuccess
        Left err -> putStrLn err >> exitFailure
