# Banyan

Visualize Dropbox file and directory sizes.

![](./docs/screenshot.png)

## Develop

### Install

Install [yarn](https://yarnpkg.com).

```bash
$ yarn install
```

### Create a Dropbox API Key

Sign into Dropbox.

[Create a new app](https://www.dropbox.com/developers/apps/create). Select
“Dropbox API”, and give it “Full Dropbox” access.

![](./docs/dropbox-create-app.png)

Add `http://localhost:4000/` to the list of Redirect URIs.

Set the `DROPBOX_APP_KEY` environment variable to the app's API key (highlighted
below). If you use [direnv](https://direnv.net/), you can copy `.envrc.template`
to `.envrc` and edit the key into that file.

![](./docs/dropbox-app-settings.png)

### Run

```bash
$ yarn start
```

### Test

```bash
$ yarn test        # run the tests once
$ yarn test:watch  # test in watch mode
```

### Lint

```bash
$ yarn lint
```

## Acknowledgements

Build with [Elm](http://elm-lang.org/),
[elm-dropbox](http://package.elm-lang.org/packages/avh4/elm-dropbox/latest),
[D3](http://d3js.org/), [Semantic UI](https://semantic-ui.com/), and
[Poi](https://poi.js.org/#/).

The [Banyan tree
image](<https://commons.wikimedia.org/wiki/File:Banyan_tree_(PSF).png>) used in
this app's Dropbox OAuth page was donated to the Wikimedia Foundation by Pearson
Scott Foresman. It is in the public domain.

## License

MIT
