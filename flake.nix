{
  description = "userver framework";

  # Current limitations (todo-list):
  # - nix develop only. No nix build, since build requires to install pip packages
  # - No tests. Some tests require pip (again)
  # - No feature flags. Though, should be easy to add
  # - No version checks. Some packages are not found by cmake, since it checks version in a wrong way
  # - Only kafka feature is enabled. Other features are disabled
  # - Boost stacktrace is not working. Disabled for now

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { nixpkgs, ... }: rec {
    packages.x86_64-linux.default = packages.x86_64-linux.userver;
    packages.x86_64-linux.userver = let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in pkgs.stdenv.mkDerivation {
      name = "userver";
      src = ./.;
      nativeBuildInputs = with pkgs; [ cmake cmakeCurses ninja gcc ];
      buildInputs = with pkgs; [ 
        clang-tools # for clang-format
        pkg-config
        gtest
        gbenchmark
        # When boost updates to new version, we'll be fine
        # but for now, '-DUSERVER_FEATURE_STACKTRACE=OFF' is needed
        (boost187.override { extraB2Args = ["boost.stacktrace.from_exception=on"]; }) # it still does not work yet
        python3
        openssl_3_3
        yaml-cpp
        zstd
        icu
        zlib
        nghttp2
        libev
        fmt
        # For this libs for cmake to find them, use '-DUSERVER_CHECK_PACKAGE_VERSIONS=0'
        # to disable version checks. This is a workaround for the fact that the
        # version check compares smth like 11.0.0 with 20210329, which does not work well.
        cryptopp
        cctz
        
        re2
        jemalloc
        rapidjson
        c-ares
      ] ++ (if true then [ # TODO: Flag for -DUSERVER_FEATURE_KAFKA
        lz4
        cyrus_sasl
        curl
        rdkafka
      ] else []);

      configurePhase = ''
        cmake -B build_debug -DUSERVER_FEATURE_STACKTRACE=OFF "-DUSERVER_SANITIZE=addr;ub" -GNinja
      '';
      buildPhase = ''
        cmake --build build_debug --parallel
      ''; # TODO: Threads number
      installPhase = ''
        cmake --install build_debug --prefix $out
      '';
    };

  };
}
