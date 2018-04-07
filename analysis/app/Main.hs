module Main where

import           Control.Monad        (when)
import qualified Data.ByteString.Lazy as BL
import qualified Data.Csv
import           Data.List
import           Data.List.Split      (splitOn)
import           Data.Semigroup       ((<>))
import           Options.Applicative

import           FilePathExtras
import           Serialize

-- OPTIONS

data Options = Options
  { getShowPaths     :: Bool
  , getSortFlag      :: Bool
  , getDotsFlag      :: Bool
  , getMultidotsFlag :: Bool
  , getInputFile     :: String
  , getOutputFile    :: Maybe String
  , getCsvOutputFile :: Maybe String
  }

getRelativizer :: Options -> Relativizer
getRelativizer opts =
  case (getDotsFlag opts, getMultidotsFlag opts) of
    (False, _)    -> makeRelative
    (True, False) -> makeRelativeIfShorter makeRelativeWithDots
    (True, True)  -> makeRelativeIfShorter makeRelativeWithMultidots

getPathSorter :: Options -> [FilePath] -> [FilePath]
getPathSorter opts =
  if getSortFlag opts
    then sortBy compareByDirectory
    else id

options :: Parser Options
options =
  Options
  <$> switch (long "paths" <> short 'p' <> help "Show paths")
  <*> switch (long "sort" <> help "Sort files before directories")
  <*> switch (long "allow-dots" <> short 'd' <> help "Allow .. in relative pathnames")
  <*> switch (long "combine-dots" <> short 'm' <> help "Allow ... etc. in pathnames")
  <*> argument str (metavar "FILE")
  <*> optional (strOption
      (long "output" <> short 'o' <> metavar "FILE" <> help "Write output to FILE"))
    <*> optional (strOption
    (long "csv" <> metavar "FILE" <> help "Write CSV output to FILE"))

-- MAIN

run :: Options -> IO ()
run opts = do
  content <- dropFinalNewline <$> readFile (getInputFile opts)
  let encoder = mkFilePathsEncoder $ getRelativizer opts
      inPaths     = entryPaths content
      absPaths    = decodeFilePaths inPaths
      sortedPaths = getPathSorter opts absPaths
      outPaths    = encoder sortedPaths
      outString   = unEntryPaths outPaths
  putStrLn $ "input size : " ++ show (length content)
  putStrLn $ "output size: " ++ show (length outString)
  when (getShowPaths opts) $ do
    putStrLn $ "input   : " ++ show inPaths
    putStrLn $ "decoded : " ++ show absPaths
    putStrLn $ "re-coded: " ++ show outPaths
  case getCsvOutputFile opts of
    Nothing -> return ()
    Just outfile -> do
      let csv = Data.Csv.encode $ fileSizes absPaths
      BL.writeFile outfile csv
      putStrLn $ "Wrote CSV to " ++ outfile
  case getOutputFile opts of
    Nothing      -> return ()
    Just outfile -> writeFile outfile outString

main :: IO ()
main = run =<< execParser opts
  where
    opts = info (options <**> helper)
        (fullDesc <> progDesc "Report path cache metrics" <>
         header "analyze - report path cache metrics")

-- HELPERS

-- | Drop a final newline if present.
dropFinalNewline :: String -> String
dropFinalNewline = reverse . dropWhile (== '\n') . reverse

-- ENTRY PATH SEPARATORS

-- | The character that separates paths.
entryPathSeparator :: String
entryPathSeparator = ":"

{-| `entryPaths` breaks a string up into a list of paths, which were delimited
by colons.
-}
entryPaths :: String -> [FilePath]
entryPaths = splitOn entryPathSeparator

{-| `unEntryPaths` is an inverse operation to `entryPaths`. It uses separating
colons to join paths.
-}
unEntryPaths :: [FilePath] -> String
unEntryPaths = intercalate entryPathSeparator
