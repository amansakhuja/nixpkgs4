/* String manipulation functions. */
{ lib }:
let

inherit (builtins) length;

in

rec {

  inherit (builtins) stringLength substring head tail isString replaceStrings;

  /* Concatenate a list of strings.

    Type: concatStrings :: [string] -> string

     Example:
       concatStrings ["foo" "bar"]
       => "foobar"
  */
  concatStrings = builtins.concatStringsSep "";

  /* Map a function over a list and concatenate the resulting strings.

    Type: concatMapStrings :: (a -> string) -> [a] -> string

     Example:
       concatMapStrings (x: "a" + x) ["foo" "bar"]
       => "afooabar"
  */
  concatMapStrings = f: list: concatStrings (map f list);

  /* Like `concatMapStrings` except that the f functions also gets the
     position as a parameter.

     Type: concatImapStrings :: (int -> a -> string) -> [a] -> string

     Example:
       concatImapStrings (pos: x: "${toString pos}-${x}") ["foo" "bar"]
       => "1-foo2-bar"
  */
  concatImapStrings = f: list: concatStrings (lib.imap1 f list);

  /* Place an element between each element of a list

     Type: intersperse :: a -> [a] -> [a]

     Example:
       intersperse "/" ["usr" "local" "bin"]
       => ["usr" "/" "local" "/" "bin"].
  */
  intersperse =
    # Separator to add between elements
    separator:
    # Input list
    list:
    if list == [] || length list == 1
    then list
    else tail (lib.concatMap (x: [separator x]) list);

  /* Concatenate a list of strings with a separator between each element

     Type: concatStringsSep :: string -> [string] -> string

     Example:
        concatStringsSep "/" ["usr" "local" "bin"]
        => "usr/local/bin"
  */
  concatStringsSep = builtins.concatStringsSep or (separator: list:
    concatStrings (intersperse separator list));

  /* Maps a function over a list of strings and then concatenates the
     result with the specified separator interspersed between
     elements.

     Type: concatMapStringsSep :: string -> (string -> string) -> [string] -> string

     Example:
        concatMapStringsSep "-" (x: toUpper x)  ["foo" "bar" "baz"]
        => "FOO-BAR-BAZ"
  */
  concatMapStringsSep =
    # Separator to add between elements
    sep:
    # Function to map over the list
    f:
    # List of input strings
    list: concatStringsSep sep (map f list);

  /* Same as `concatMapStringsSep`, but the mapping function
     additionally receives the position of its argument.

     Type: concatMapStringsSep :: string -> (int -> string -> string) -> [string] -> string

     Example:
       concatImapStringsSep "-" (pos: x: toString (x / pos)) [ 6 6 6 ]
       => "6-3-2"
  */
  concatImapStringsSep =
    # Separator to add between elements
    sep:
    # Function that receives elements and their positions
    f:
    # List of input strings
    list: concatStringsSep sep (lib.imap1 f list);

  /* Construct a Unix-style, colon-separated search path consisting of
     the given `subDir` appended to each of the given paths.

     Type: makeSearchPath :: string -> [string] -> string

     Example:
       makeSearchPath "bin" ["/root" "/usr" "/usr/local"]
       => "/root/bin:/usr/bin:/usr/local/bin"
       makeSearchPath "bin" [""]
       => "/bin"
  */
  makeSearchPath =
    # Directory name to append
    subDir:
    # List of base paths
    paths:
    concatStringsSep ":" (map (path: path + "/" + subDir) (builtins.filter (x: x != null) paths));

  /* Construct a Unix-style search path by appending the given
     `subDir` to the specified `output` of each of the packages. If no
     output by the given name is found, fallback to `.out` and then to
     the default.

     Type: string -> string -> [package] -> string

     Example:
       makeSearchPathOutput "dev" "bin" [ pkgs.openssl pkgs.zlib ]
       => "/nix/store/9rz8gxhzf8sw4kf2j2f1grr49w8zx5vj-openssl-1.0.1r-dev/bin:/nix/store/wwh7mhwh269sfjkm6k5665b5kgp7jrk2-zlib-1.2.8/bin"
  */
  makeSearchPathOutput =
    # Package output to use
    output:
    # Directory name to append
    subDir:
    # List of packages
    pkgs: makeSearchPath subDir (map (lib.getOutput output) pkgs);

  /* Construct a library search path (such as RPATH) containing the
     libraries for a set of packages

     Example:
       makeLibraryPath [ "/usr" "/usr/local" ]
       => "/usr/lib:/usr/local/lib"
       pkgs = import <nixpkgs> { }
       makeLibraryPath [ pkgs.openssl pkgs.zlib ]
       => "/nix/store/9rz8gxhzf8sw4kf2j2f1grr49w8zx5vj-openssl-1.0.1r/lib:/nix/store/wwh7mhwh269sfjkm6k5665b5kgp7jrk2-zlib-1.2.8/lib"
  */
  makeLibraryPath = makeSearchPathOutput "lib" "lib";

  /* Construct a binary search path (such as $PATH) containing the
     binaries for a set of packages.

     Example:
       makeBinPath ["/root" "/usr" "/usr/local"]
       => "/root/bin:/usr/bin:/usr/local/bin"
  */
  makeBinPath = makeSearchPathOutput "bin" "bin";


  /* Construct a perl search path (such as $PERL5LIB)

     Example:
       pkgs = import <nixpkgs> { }
       makePerlPath [ pkgs.perlPackages.libnet ]
       => "/nix/store/n0m1fk9c960d8wlrs62sncnadygqqc6y-perl-Net-SMTP-1.25/lib/perl5/site_perl"
  */
  # FIXME(zimbatm): this should be moved in perl-specific code
  makePerlPath = makeSearchPathOutput "lib" "lib/perl5/site_perl";

  /* Construct a perl search path recursively including all dependencies (such as $PERL5LIB)

     Example:
       pkgs = import <nixpkgs> { }
       makeFullPerlPath [ pkgs.perlPackages.CGI ]
       => "/nix/store/fddivfrdc1xql02h9q500fpnqy12c74n-perl-CGI-4.38/lib/perl5/site_perl:/nix/store/8hsvdalmsxqkjg0c5ifigpf31vc4vsy2-perl-HTML-Parser-3.72/lib/perl5/site_perl:/nix/store/zhc7wh0xl8hz3y3f71nhlw1559iyvzld-perl-HTML-Tagset-3.20/lib/perl5/site_perl"
  */
  makeFullPerlPath = deps: makePerlPath (lib.misc.closePropagation deps);

  /* Depending on the boolean `cond', return either the given string
     or the empty string. Useful to concatenate against a bigger string.

     Type: optionalString :: bool -> string -> string

     Example:
       optionalString true "some-string"
       => "some-string"
       optionalString false "some-string"
       => ""
  */
  optionalString =
    # Condition
    cond:
    # String to return if condition is true
    string: if cond then string else "";

  /* Determine whether a string has given prefix.

     Type: hasPrefix :: string -> string -> bool

     Example:
       hasPrefix "foo" "foobar"
       => true
       hasPrefix "foo" "barfoo"
       => false
  */
  hasPrefix =
    # Prefix to check for
    pref:
    # Input string
    str: substring 0 (stringLength pref) str == pref;

  /* Determine whether a string has given suffix.

     Type: hasSuffix :: string -> string -> bool

     Example:
       hasSuffix "foo" "foobar"
       => false
       hasSuffix "foo" "barfoo"
       => true
  */
  hasSuffix =
    # Suffix to check for
    suffix:
    # Input string
    content:
    let
      lenContent = stringLength content;
      lenSuffix = stringLength suffix;
    in lenContent >= lenSuffix &&
       substring (lenContent - lenSuffix) lenContent content == suffix;

  /* Determine whether a string contains the given infix

    Type: hasInfix :: string -> string -> bool

    Example:
      hasInfix "bc" "abcd"
      => true
      hasInfix "ab" "abcd"
      => true
      hasInfix "cd" "abcd"
      => true
      hasInfix "foo" "abcd"
      => false
  */
  hasInfix = infix: content:
    let
      drop = x: substring 1 (stringLength x) x;
    in hasPrefix infix content
      || content != "" && hasInfix infix (drop content);

  /* Convert a string to a list of characters (i.e. singleton strings).
     This allows you to, e.g., map a function over each character.  However,
     note that this will likely be horribly inefficient; Nix is not a
     general purpose programming language. Complex string manipulations
     should, if appropriate, be done in a derivation.
     Also note that Nix treats strings as a list of bytes and thus doesn't
     handle unicode.

     Type: stringtoCharacters :: string -> [string]

     Example:
       stringToCharacters ""
       => [ ]
       stringToCharacters "abc"
       => [ "a" "b" "c" ]
       stringToCharacters "💩"
       => [ "�" "�" "�" "�" ]
  */
  stringToCharacters = s:
    map (p: substring p 1 s) (lib.range 0 (stringLength s - 1));

  /* Manipulate a string character by character and replace them by
     strings before concatenating the results.

     Type: stringAsChars :: (string -> string) -> string -> string

     Example:
       stringAsChars (x: if x == "a" then "i" else x) "nax"
       => "nix"
  */
  stringAsChars =
    # Function to map over each individual character
    f:
    # Input string
    s: concatStrings (
      map f (stringToCharacters s)
    );

  /* Escape occurrence of the elements of `list` in `string` by
     prefixing it with a backslash.

     Type: escape :: [string] -> string -> string

     Example:
       escape ["(" ")"] "(foo)"
       => "\\(foo\\)"
  */
  escape = list: replaceChars list (map (c: "\\${c}") list);

  /* Quote string to be used safely within the Bourne shell.

     Type: escapeShellArg :: string -> string

     Example:
       escapeShellArg "esc'ape\nme"
       => "'esc'\\''ape\nme'"
  */
  escapeShellArg = arg: "'${replaceStrings ["'"] ["'\\''"] (toString arg)}'";

  /* Quote all arguments to be safely passed to the Bourne shell.

     Type: escapeShellArgs :: [string] -> string

     Example:
       escapeShellArgs ["one" "two three" "four'five"]
       => "'one' 'two three' 'four'\\''five'"
  */
  escapeShellArgs = concatMapStringsSep " " escapeShellArg;

  /* Turn a string into a Nix expression representing that string

     Type: string -> string

     Example:
       escapeNixString "hello\${}\n"
       => "\"hello\\\${}\\n\""
  */
  escapeNixString = s: escape ["$"] (builtins.toJSON s);

  # Obsolete - use replaceStrings instead.
  replaceChars = builtins.replaceStrings or (
    del: new: s:
    let
      substList = lib.zipLists del new;
      subst = c:
        let found = lib.findFirst (sub: sub.fst == c) null substList; in
        if found == null then
          c
        else
          found.snd;
    in
      stringAsChars subst s);

  # Case conversion utilities.
  lowerChars = stringToCharacters "abcdefghijklmnopqrstuvwxyz";
  upperChars = stringToCharacters "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

  /* Converts an ASCII string to lower-case.

     Type: toLower :: string -> string

     Example:
       toLower "HOME"
       => "home"
  */
  toLower = replaceChars upperChars lowerChars;

  /* Converts an ASCII string to upper-case.

     Type: toUpper :: string -> string

     Example:
       toUpper "home"
       => "HOME"
  */
  toUpper = replaceChars lowerChars upperChars;

  /* Appends string context from another string.  This is an implementation
     detail of Nix.

     Strings in Nix carry an invisible `context` which is a list of strings
     representing store paths.  If the string is later used in a derivation
     attribute, the derivation will properly populate the inputDrvs and
     inputSrcs.

     Example:
       pkgs = import <nixpkgs> { };
       addContextFrom pkgs.coreutils "bar"
       => "bar"
  */
  addContextFrom = a: b: substring 0 0 a + b;

  /* Cut a string with a separator and produces a list of strings which
     were separated by this separator.

     NOTE: this function is not performant and should never be used.

     Example:
       splitString "." "foo.bar.baz"
       => [ "foo" "bar" "baz" ]
       splitString "/" "/usr/local/bin"
       => [ "" "usr" "local" "bin" ]
  */
  splitString = _sep: _s:
    let
      sep = addContextFrom _s _sep;
      s = addContextFrom _sep _s;
      sepLen = stringLength sep;
      sLen = stringLength s;
      lastSearch = sLen - sepLen;
      startWithSep = startAt:
        substring startAt sepLen s == sep;

      recurse = index: startAt:
        let cutUntil = i: [(substring startAt (i - startAt) s)]; in
        if index <= lastSearch then
          if startWithSep index then
            let restartAt = index + sepLen; in
            cutUntil index ++ recurse restartAt restartAt
          else
            recurse (index + 1) startAt
        else
          cutUntil sLen;
    in
      recurse 0 0;

  /* Return a string without the specified prefix, if the prefix matches.

     Type: string -> string -> string

     Example:
       removePrefix "foo." "foo.bar.baz"
       => "bar.baz"
       removePrefix "xxx" "foo.bar.baz"
       => "foo.bar.baz"
  */
  removePrefix =
    # Prefix to remove if it matches
    prefix:
    # Input string
    str:
    let
      preLen = stringLength prefix;
      sLen = stringLength str;
    in
      if hasPrefix prefix str then
        substring preLen (sLen - preLen) str
      else
        str;

  /* Return a string without the specified suffix, if the suffix matches.

     Type: string -> string -> string

     Example:
       removeSuffix "front" "homefront"
       => "home"
       removeSuffix "xxx" "homefront"
       => "homefront"
  */
  removeSuffix =
    # Suffix to remove if it matches
    suffix:
    # Input string
    str:
    let
      sufLen = stringLength suffix;
      sLen = stringLength str;
    in
      if sufLen <= sLen && suffix == substring (sLen - sufLen) sufLen str then
        substring 0 (sLen - sufLen) str
      else
        str;

  /* Return true if string v1 denotes a version older than v2.

     Example:
       versionOlder "1.1" "1.2"
       => true
       versionOlder "1.1" "1.1"
       => false
  */
  versionOlder = v1: v2: builtins.compareVersions v2 v1 == 1;

  /* Return true if string v1 denotes a version equal to or newer than v2.

     Example:
       versionAtLeast "1.1" "1.0"
       => true
       versionAtLeast "1.1" "1.1"
       => true
       versionAtLeast "1.1" "1.2"
       => false
  */
  versionAtLeast = v1: v2: !versionOlder v1 v2;

  /* This function takes an argument that's either a derivation or a
     derivation's "name" attribute and extracts the version part from that
     argument.

     Example:
       getVersion "youtube-dl-2016.01.01"
       => "2016.01.01"
       getVersion pkgs.youtube-dl
       => "2016.01.01"
  */
  getVersion = x:
   let
     parse = drv: (builtins.parseDrvName drv).version;
   in if isString x
      then parse x
      else x.version or (parse x.name);

  /* Extract name with version from URL. Ask for separator which is
     supposed to start extension.

     Example:
       nameFromURL "https://nixos.org/releases/nix/nix-1.7/nix-1.7-x86_64-linux.tar.bz2" "-"
       => "nix"
       nameFromURL "https://nixos.org/releases/nix/nix-1.7/nix-1.7-x86_64-linux.tar.bz2" "_"
       => "nix-1.7-x86"
  */
  nameFromURL = url: sep:
    let
      components = splitString "/" url;
      filename = lib.last components;
      name = builtins.head (splitString sep filename);
    in assert name !=  filename; name;

  /* Create an --{enable,disable}-<feat> string that can be passed to
     standard GNU Autoconf scripts.

     Example:
       enableFeature true "shared"
       => "--enable-shared"
       enableFeature false "shared"
       => "--disable-shared"
  */
  enableFeature = enable: feat: "--${if enable then "enable" else "disable"}-${feat}";

  /* Create an --{enable-<feat>=<value>,disable-<feat>} string that can be passed to
     standard GNU Autoconf scripts.

     Example:
       enableFeature true "shared" "foo"
       => "--enable-shared=foo"
       enableFeature false "shared" (throw "ignored")
       => "--disable-shared"
  */
  enableFeatureAs = enable: feat: value: enableFeature enable feat + optionalString enable "=${value}";

  /* Create an --{with,without}-<feat> string that can be passed to
     standard GNU Autoconf scripts.

     Example:
       withFeature true "shared"
       => "--with-shared"
       withFeature false "shared"
       => "--without-shared"
  */
  withFeature = with_: feat: "--${if with_ then "with" else "without"}-${feat}";

  /* Create an --{with-<feat>=<value>,without-<feat>} string that can be passed to
     standard GNU Autoconf scripts.

     Example:
       with_Feature true "shared" "foo"
       => "--with-shared=foo"
       with_Feature false "shared" (throw "ignored")
       => "--without-shared"
  */
  withFeatureAs = with_: feat: value: withFeature with_ feat + optionalString with_ "=${value}";

  /* Create a fixed width string with additional prefix to match
     required width.

     This function will fail if the input string is longer than the
     requested length.

     Type: fixedWidthString :: int -> string -> string

     Example:
       fixedWidthString 5 "0" (toString 15)
       => "00015"
  */
  fixedWidthString = width: filler: str:
    let
      strw = lib.stringLength str;
      reqWidth = width - (lib.stringLength filler);
    in
      assert strw <= width;
      if strw == width then str else filler + fixedWidthString reqWidth filler str;

  /* Format a number adding leading zeroes up to fixed width.

     Example:
       fixedWidthNumber 5 15
       => "00015"
  */
  fixedWidthNumber = width: n: fixedWidthString width "0" (toString n);

  /* Check whether a value can be coerced to a string */
  isCoercibleToString = x:
    builtins.elem (builtins.typeOf x) [ "path" "string" "null" "int" "float" "bool" ] ||
    (builtins.isList x && lib.all isCoercibleToString x) ||
    x ? outPath ||
    x ? __toString;

  /* Check whether a value is a store path.

     Example:
       isStorePath "/nix/store/d945ibfx9x185xf04b890y4f9g3cbb63-python-2.7.11/bin/python"
       => false
       isStorePath "/nix/store/d945ibfx9x185xf04b890y4f9g3cbb63-python-2.7.11/"
       => true
       isStorePath pkgs.python
       => true
       isStorePath [] || isStorePath 42 || isStorePath {} || …
       => false
  */
  isStorePath = x:
       isCoercibleToString x
    && builtins.substring 0 1 (toString x) == "/"
    && dirOf (builtins.toPath x) == builtins.storeDir;

  /* Parse a string string as an int.

     Type: string -> int

     Example:
       toInt "1337"
       => 1337
       toInt "-4"
       => -4
       toInt "3.14"
       => error: floating point JSON numbers are not supported
  */
  # Obviously, it is a bit hacky to use fromJSON this way.
  toInt = str:
    let may_be_int = builtins.fromJSON str; in
    if builtins.isInt may_be_int
    then may_be_int
    else throw "Could not convert ${str} to int.";

  /* Read a list of paths from `file`, relative to the `rootPath`.
     Lines beginning with `#` are treated as comments and ignored.
     Whitespace is significant.

     NOTE: This function is not performant and should be avoided.

     Example:
       readPathsFromFile /prefix
         ./pkgs/development/libraries/qt-5/5.4/qtbase/series
       => [ "/prefix/dlopen-resolv.patch" "/prefix/tzdir.patch"
            "/prefix/dlopen-libXcursor.patch" "/prefix/dlopen-openssl.patch"
            "/prefix/dlopen-dbus.patch" "/prefix/xdg-config-dirs.patch"
            "/prefix/nix-profiles-library-paths.patch"
            "/prefix/compose-search-path.patch" ]
  */
  readPathsFromFile = rootPath: file:
    let
      root = toString rootPath;
      lines = lib.splitString "\n" (builtins.readFile file);
      removeComments = lib.filter (line: line != "" && !(lib.hasPrefix "#" line));
      relativePaths = removeComments lines;
      absolutePaths = builtins.map (path: builtins.toPath (root + "/" + path)) relativePaths;
    in
      absolutePaths;

  /* Read the contents of a file removing the trailing \n

     Type: fileContents :: path -> string

     Example:
       $ echo "1.0" > ./version

       fileContents ./version
       => "1.0"
  */
  fileContents = file: removeSuffix "\n" (builtins.readFile file);
}
