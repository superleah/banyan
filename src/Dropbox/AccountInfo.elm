port module Dropbox.AccountInfo
    exposing
        ( AccountInfo
        , extractAccessToken
        , getAccountInfo
        , receiveFullAccountInfo
        )

import Dropbox exposing (..)
import Extras exposing (..)
import Regex
import Json.Decode
import Json.Decode.Dropbox exposing (optional)
import Json.Decode.Pipeline as Pipeline


-- DATA


type alias BaseAccountInfo a =
    { a
        | accountId : String
        , name : AccountName
        , email : String
        , emailVerified : Bool
        , disabled : Bool
        , profilePhotoUrl : Maybe String
        , teamMemberId : Maybe String
    }


type alias BasicAccount =
    BaseAccountInfo
        { isTeammate : Bool
        }


type alias AccountInfo =
    BaseAccountInfo
        { locale : String
        , referralLink : String
        , isPaired : Bool
        , accountType : AccountType
        , rootInfo : AccountRootInfo
        , country : String
        , team : Maybe FullTeam
        }


type alias FullAccountInfo =
    { accountId : String
    , name : AccountName
    , email : String
    , emailVerified : Bool
    , disabled : Bool
    , locale : String
    , referralLink : String
    , isPaired : Bool
    , accountType : AccountType
    , rootInfo : AccountRootInfo
    , profilePhotoUrl : Maybe String
    , country : String
    , team : Maybe FullTeam
    , teamMemberId : Maybe String
    }


decodeFullAccount : Json.Decode.Decoder FullAccountInfo
decodeFullAccount =
    Pipeline.decode FullAccountInfo
        |> Pipeline.required "account_id" Json.Decode.string
        |> Pipeline.required "name" decodeAccountName
        |> Pipeline.required "email" Json.Decode.string
        |> Pipeline.required "email_verified" Json.Decode.bool
        |> Pipeline.required "disabled" Json.Decode.bool
        |> Pipeline.required "locale" Json.Decode.string
        |> Pipeline.required "referral_link" Json.Decode.string
        |> Pipeline.required "is_paired" Json.Decode.bool
        |> Pipeline.required "account_type" decodeAccountType
        |> Pipeline.required "root_info" decodeAccountRootInfo
        |> optional "profile_photo_url" Json.Decode.string
        |> Pipeline.required "country" Json.Decode.string
        |> optional "team" decodeFullTeam
        |> optional "team_member_id" Json.Decode.string


type AccountType
    = BasicAccount
    | ProAccount
    | BusinessAccount


decodeAccountType : Json.Decode.Decoder AccountType
decodeAccountType =
    Json.Decode.field ".tag" Json.Decode.string
        |> Json.Decode.andThen
            (\str ->
                case str of
                    "basic" ->
                        Json.Decode.succeed BasicAccount

                    "pro" ->
                        Json.Decode.succeed ProAccount

                    "business" ->
                        Json.Decode.succeed BusinessAccount

                    s ->
                        Json.Decode.fail <| "Unknown account type: " ++ s
            )


type alias AccountName =
    { givenName : String
    , surname : String
    , familiarName : String
    , displayName : String
    , abbreviatedName : String
    }


decodeAccountName : Json.Decode.Decoder AccountName
decodeAccountName =
    Pipeline.decode AccountName
        |> Pipeline.required "given_name" Json.Decode.string
        |> Pipeline.required "surname" Json.Decode.string
        |> Pipeline.required "familiar_name" Json.Decode.string
        |> Pipeline.required "display_name" Json.Decode.string
        |> Pipeline.required "abbreviated_name" Json.Decode.string


type alias AccountRootInfo =
    { --- TODO tag
      rootNamespaceId : String
    , homeNamespaceId : String
    }



-- = TeamRootInfo { root_namespace_id: String, home_namespace_id: String, home_path: String}
-- | UserRootInfo { root_namespace_id: String, home_namespace_id: String}


decodeAccountRootInfo : Json.Decode.Decoder AccountRootInfo
decodeAccountRootInfo =
    Pipeline.decode AccountRootInfo
        |> Pipeline.required "root_namespace_id" Json.Decode.string
        |> Pipeline.required "home_namespace_id" Json.Decode.string


type alias FullTeam =
    { id : String
    , name : String

    -- , sharingPolicies: TeamSharingPolicies
    -- , officeAddinPolicy: OfficeAddinPolicy = Enabled | Disabled
    }


decodeFullTeam : Json.Decode.Decoder FullTeam
decodeFullTeam =
    Pipeline.decode FullTeam
        |> Pipeline.required "id" Json.Decode.string
        |> Pipeline.required "name" Json.Decode.string


type alias TeamSharingPolicies =
    { sharedFolderMemberPolicy : String -- Team | Anyone
    , sharedFolderJoinPolicy : String -- Team | Anyone
    , sharedLinkCreatePolicy : String -- Public | Team | Anyone
    }



-- ACCESS TOKEN


bearerRegex : Regex.Regex
bearerRegex =
    Regex.regex "Bearer \"(.+)\""


extractAccessToken : UserAuth -> Maybe String
extractAccessToken auth =
    -- TODO extract from JSON instead?
    auth |> Basics.toString |> firstMatch bearerRegex



-- PORTS


port getAccountInfo : String -> Cmd msg


port receiveRawFullAccountInfo : (Json.Decode.Value -> msg) -> Sub msg


receiveFullAccountInfo : (Result String AccountInfo -> msg) -> Sub msg
receiveFullAccountInfo sub =
    receiveRawFullAccountInfo (sub << Json.Decode.decodeValue decodeFullAccount)
