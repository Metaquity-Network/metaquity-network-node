#!/bin/bash

ZOMBIENET_V=v1.3.68
POLKADOT_V=polkadot-v1.2.0

POLKADOT_FILES=(
  "polkadot"
  "polkadot-execute-worker"
  "polkadot-prepare-worker"
)

case "$(uname -s)" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=Mac;;
    *)          exit 1
esac

if [ $MACHINE = "Linux" ]; then
  ZOMBIENET_BIN=zombienet-linux-x64
elif [ $MACHINE = "Mac" ]; then
  ZOMBIENET_BIN=zombienet-macos
fi

build_polkadot(){
  echo "cloning polkadot repository..."
  CWD=$(pwd)
  mkdir -p bin
  pushd /tmp
    git clone https://github.com/paritytech/polkadot-sdk.git
    pushd polkadot-sdk
      git checkout polkadot-$POLKADOT_V
      echo "building polkadot executable..."
      cargo build --release --features fast-runtime
      cp ${POLKADOT_FILES[@]/#/target/release/} $CWD/bin
    popd
  popd
}

zombienet_init() {
  if [ ! -f $ZOMBIENET_BIN ]; then
    echo "fetching zombienet executable..."
    curl -LO https://github.com/paritytech/zombienet/releases/download/$ZOMBIENET_V/$ZOMBIENET_BIN
    chmod +x $ZOMBIENET_BIN
  fi
  for file in "${POLKADOT_FILES[@]}"; do
      [[ -f "bin/$file" ]] || { build_polkadot; break; }
  done
}

zombienet_spawn() {
  zombienet_init
  if [ ! -f target/release/metaquity-network ]; then
    echo "building metaquity-network..."
    cargo build --release
  fi
  echo "spawning polkadot-local relay chain plus metaquity-network..."
  ./$ZOMBIENET_BIN spawn zombienet-config/rococo-local-config.toml -p native
}

print_help() {
  echo "This is a shell script to automate the execution of zombienet."
  echo ""
  echo "$ ./zombienet.sh init         # fetches zombienet and polkadot executables"
  echo "$ ./zombienet.sh spawn        # spawns a rococo-local relay chain plus metaquity-network"
}

SUBCOMMAND=$1
case $SUBCOMMAND in
  "" | "-h" | "--help")
    print_help
    ;;
  *)
    shift
    zombienet_${SUBCOMMAND} $@
    if [ $? = 127 ]; then
      echo "Error: '$SUBCOMMAND' is not a known SUBCOMMAND." >&2
      echo "Run './zombienet.sh --help' for a list of known subcommands." >&2
        exit 1
    fi
  ;;
esac
