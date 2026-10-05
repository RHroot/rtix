function nix-clean
    set_color green; echo "🚀 Starting deep Nix cleanup..."
    set_color normal

    # 1. Wipe old generations and collect garbage
    set_color yellow; echo "🧹 Step 1: Deleting all old generations (GC)..."
    set_color normal
    sudo nix-collect-garbage -d

    # 2. Clear user cache (removes old downloaded tarballs/eval caches)
    set_color yellow; echo "🗑️  Step 2: Clearing Nix cache..."
    set_color normal
    rm -rf ~/.cache/nix

    # 3. Deduplicate the Nix store
    set_color yellow; echo "💎 Step 3: Optimizing store (this may take a moment)..."
    set_color normal
    sudo nix-store --optimise

    # 4. Calculate and display final size
    set_color cyan; echo "📊 Calculating final /nix/store size..."
    set_color normal

    set -l store_size (du -sh /nix/store 2>/dev/null | cut -f1)

    set_color green; echo "✅ Cleanup complete!"
    set_color cyan; echo "📦 Current /nix/store size: $store_size"
    set_color normal
end
