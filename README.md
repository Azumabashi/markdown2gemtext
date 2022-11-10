# markdown2gemtext
Script converts from markdown to gemtext implemented with Nim.

## Dependencies

- Nim
- markdown
  - install with `nimble install markdown`

## Usage

```
$ git clone https://github.com/Azumabashi/markdown2gemtext
$ cd markdown2gemtext
$ nim c -r markdown2gemtext dir https://your.domain path/to/savepath
```

where `dir` is a path to directory which convert target markdown files are saved, and the third argument `path/to/savepath` can be omitted.

Sample markdown file is in the `sample` directory.

The output is generated under `gemtext/` by default.

## License
MIT
