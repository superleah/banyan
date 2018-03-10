module FileTreeTests exposing (..)

import Expect exposing (Expectation)
import FileEntry exposing (..)
import FileTree exposing (..)
import Test exposing (..)


suite : Test
suite =
    describe "FileTree"
        [ describe "fromString"
            [ test "creates files" <|
                \_ ->
                    FileTree.fromString "/a;/b:12"
                        |> Expect.all
                            [ get "/a"
                                >> expectJust (FileEntry.File { key = "/a", path = "/a", size = Nothing })
                            , get "/b"
                                >> expectJust (fileEntry "/b" 12)
                            ]
            , test "creates directories" <|
                \_ ->
                    FileTree.fromString "/dir/"
                        |> get "/dir"
                        >> expectJust (dirEntry "/dir")
            ]
        , describe "toString"
            [ test "prints files, file sizes, and directories" <|
                \_ ->
                    FileTree.fromString "/a;/b/;/c:12"
                        |> FileTree.toString
                        |> Expect.equal "/a;/b/;/c:12"
            ]
        , test "/dir/ creates a directory node" <|
            \_ ->
                FileTree.fromString "/dir/"
                    |> get "/dir"
                    |> expectJust (dirEntry "/dir")
        , test "/dir/leaf creates the intermediate directory node" <|
            \_ ->
                FileTree.fromString "/dir/leaf"
                    |> get "/dir"
                    |> expectJust (dirEntry "/dir")
        , test "/dir/subdir/ creates a leaf node" <|
            \_ ->
                FileTree.fromString "/dir/subdir/"
                    |> get "/dir/subdir"
                    |> expectJust (dirEntry "/dir/subdir")
        , test "/dir/subdir/ + /Dir/ preserves the subdirectory" <|
            \_ ->
                FileTree.fromString "/dir/subdir/;/Dir/"
                    |> get "/dir/subdir"
                    |> expectJust (dirEntry "/dir/subdir")
        , test "/dir/leaf + /Dir/ updates the directory name" <|
            \_ ->
                FileTree.fromString "/dir/leaf;/Dir/"
                    |> get "/dir"
                    |> expectJust (dirEntry "/Dir")
        , test "/Dir/ + /dir/leaf + preserves the directory name" <|
            \_ ->
                FileTree.fromString "/Dir/;/dir/leaf"
                    |> get "/dir"
                    |> expectJust (dirEntry "/Dir")
        , test "delete /dir deletes the directory node" <|
            \_ ->
                [ dirEntry "/dir"
                , FileEntry.Deletion { key = "/dir", path = "/dir" }
                ]
                    |> fromEntries
                    |> get "/dir"
                    |> Expect.equal Nothing
        , test "delete /dir deletes the directory's children" <|
            \_ ->
                [ dirEntry "/dir"
                , dirEntry "/dir/subdir"
                , FileEntry.Deletion { key = "/dir", path = "/dir" }
                ]
                    |> fromEntries
                    |> get "/dir/subdir"
                    |> Expect.equal Nothing
        , test "delete /dir/leaf deletes only the leaf" <|
            \_ ->
                [ dirEntry "/dir"
                , dirEntry "/dir/leaf"
                , FileEntry.Deletion { key = "/dir/leaf", path = "/dir/leaf" }
                ]
                    |> fromEntries
                    |> Expect.all
                        [ get "/dir" >> expectJust (dirEntry "/dir")
                        , get "/dir/child" >> Expect.equal Nothing
                        ]
        , test "map" <|
            \_ ->
                FileTree.fromString "/a/1;/a/2;/b"
                    -- |> FileTree.map (\e -> (fromEntries <| List.singleton <| dirEntry <| .path <| itemEntry e))
                    -- TODO replace identity by an actual test
                    |> FileTree.map identity
                    |> FileTree.toString
                    |> Expect.equal "/a/;/a/1;/a/2;/b"
        , test "mapChildLists" <|
            \_ ->
                FileTree.fromString "/a/1;/a/2;/b"
                    |> mapChildLists (List.sortBy (itemEntry >> FileEntry.path) >> List.take 1)
                    |> FileTree.toString
                    |> Expect.equal "/a/;/a/1"
        , describe "combineSmallerEntries"
            [ test "combines top-level items" <|
                \_ ->
                    FileTree.fromString "/a:5;/b:4;/c:3;/d:2"
                        |> combineSmallerEntries 2 1
                        |> FileTree.toString
                        |> Expect.equal "/a:5;/b:4;/…2 smaller objects…:5"
            , test "combines non-toplevel items" <|
                \_ ->
                    FileTree.fromString "/d/f1:5;/d/f2:4;/d/f3:3"
                        |> combineSmallerEntries 2 1
                        |> FileTree.toString
                        |> Expect.equal "/d/;/d/f1:5;/d/f2:4;/d/…1 smaller object…:3"
            ]
        , test "trimDepth" <|
            \_ ->
                FileTree.fromString "/a/;/b/c"
                    |> trimDepth 1
                    |> FileTree.toString
                    |> Expect.equal "/a/;/b/"
        ]


fromEntries : List FileEntry -> FileTree
fromEntries entries =
    FileTree.empty |> addEntries entries


dirEntry : String -> FileEntry
dirEntry path =
    FileEntry.Folder { key = String.toLower path, path = path }


fileEntry : String -> Int -> FileEntry
fileEntry path size =
    FileEntry.File { key = String.toLower path, path = path, size = Just size }


expectJust : a -> Maybe a -> Expectation
expectJust =
    Expect.equal << Just
