# justfile

gitnexus-analyze:
    @echo "analyzing with gitnexus"
    npx gitnexus analyze &

gitnexus-wiki:
    @echo "creating a wiki with gitnexus"
    npx gitnexus wiki &


gitnexus-serve:
    @echo "serve gitnexus, gui at https://gitnexus.vercel.app/ " &
    @if ss -ltnp 2>/dev/null | grep -q ':4747' || lsof -i :4747 >/dev/null 2>&1; then \
        echo "Port 4747 already in use; skipping gitnexus serve."; \
    else \
        npx gitnexus@latest serve; \
    fi
