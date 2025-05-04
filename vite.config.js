import { defineConfig } from 'vite'
import elmPlugin from 'vite-plugin-elm'

export default defineConfig({
    plugins: [elmPlugin()],
    server: {
        port: 3000,
        host: true // 全てのネットワークインターフェースでリッスンするように変更
    },
})
