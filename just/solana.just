# justfile

key_path := "/home/aoi/.config/solana/id.json"

default: run-solana-local-validator

setup-solana-for-local-validator:
    #!/usr/bin/env bash
    if [ -f {{ key_path }} ]; then
        echo "Keypair already exists at {{ key_path }}"
    else
        echo "No keypair found. Generating new one..."
        solana-keygen new -o {{ key_path }}
    fi

    solana config set --url http://127.0.0.1:8899

    

run-solana-local-validator *args:
    just setup-solana-for-local-validator

    nohup solana-test-validator -r \
      --bpf-program metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s ~/.local/share/metaplex-local-validator/mpl-token-metadata.so \
      --bpf-program BGUMAp9Gq7iTEuizy4pqaxsTyUCBK68MDfK752saRPUY ~/.local/share/metaplex-local-validator/mpl-bubblegum.so \
      --bpf-program CoREENxT6tW1HoK8ypY1SxRMZTcVPm7R94rH4PZNhX7d ~/.local/share/metaplex-local-validator/mpl-core.so \
      --bpf-program hausS13jsjafwWwGqZTUQRmWyvyxn9EQpqMwV1PBBmk ~/.local/share/metaplex-local-validator/mpl-auction-house.so \
      --bpf-program neer8g6yJq2mQM6KbnViEDAD4gr3gRZyMMf4F2p3MEh ~/.local/share/metaplex-local-validator/mpl-auctioneer.so \
      --bpf-program Guard1JwRhJkVH6XZhzoYxeBVQe872VH6QggF4BWmS9g ~/.local/share/metaplex-local-validator/mpl-candy-guard.so \
      --bpf-program CndyV3LdqHUfDLmE5naZjVN8rBZz4tqhdefbAnjHG3JR ~/.local/share/metaplex-local-validator/mpl-candy-machine-v3.so \
      --bpf-program CMAGAKJ67e9hRZgfC5SFTbZH8MgEmtqazKXjmkaJjWTJ ~/.local/share/metaplex-local-validator/mpl-core-candy-guard.so \
      --bpf-program CMACYFENjoBMHzapRXyo1JZkVS6EtaDDzkjMrmQLvr4J ~/.local/share/metaplex-local-validator/mpl-core-candy-machine.so \
      --bpf-program gdrpGjVffourzkdDRrQmySw4aTHr8a3xmQzzxSwFD1a ~/.local/share/metaplex-local-validator/mpl-gumdrop.so \
      --bpf-program hyDQ4Nz1eYyegS6JfenyKwKzYxRsCWCriYSAjtzP4Vg ~/.local/share/metaplex-local-validator/mpl-hydra.so \
      --bpf-program 1NSCRfGeyo7wPUazGbaPBUsTM49e1k2aXewHGARfzSo ~/.local/share/metaplex-local-validator/mpl-inscriptions.so \
      --bpf-program MPL4o4wMzndgh8T1NVDxELQCj5UQfYTYEkabX3wNKtb ~/.local/share/metaplex-local-validator/mpl-hybrid.so \
      --bpf-program auth9SigNpDKz4sJJ1DfCTuZrZNSAgh9sFD3rboVmgg ~/.local/share/metaplex-local-validator/mpl-token-auth-rules.so \
      --bpf-program metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s ~/.local/share/metaplex-local-validator/mpl-token-metadata.so \
      {{ args }} > server.log 2>&1 &


solana-airdrop:
    just setup-solana-for-local-validator
    just run-solana-local-validator


    solana airdrop 5 &