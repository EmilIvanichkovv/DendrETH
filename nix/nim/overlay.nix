_finalNixpkgs: prevNixpkgs: {
  nim-unwrapped = prevNixpkgs.nim-unwrapped.overrideAttrs (old: {
    src = prevNixpkgs.fetchFromGitHub {
      owner = "EmilIvanichkovv";
      repo = "Nim";
      rev = "286fcef68ef6f0e3a20ab5b25307c9b4705ce54d";
      sha256 = "sha256-G3OdNI6KX7NDc4LYQxeQaaCXbFLyD0L8y2s1Q2DBO6U=";
    };
    pname = "nim-fork-unwrapped";
  });
}
