/** @type {import('next').NextConfig} */
const nextConfig = {
  // TypeScript agora BLOQUEIA o build em caso de erro (confirmado: 0 erros).
  // Isso garante que erros de tipo sejam pegos antes do deploy.
  typescript: { ignoreBuildErrors: false },
  // ESLint mantido não-bloqueante por ora, para não travar o deploy.
  // Pode ser ativado (false) depois de um `npm run lint` limpo.
  eslint: { ignoreDuringBuilds: true },
  images: { unoptimized: true },
}
module.exports = nextConfig
