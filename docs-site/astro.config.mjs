import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// Built into site/docs/ (the Pages workflow runs `npm run build`); the rest of site/ stays hand-written HTML.
export default defineConfig({
  site: 'https://velomine.eu',
  base: '/docs',
  outDir: '../site/docs',
  integrations: [
    starlight({
      title: 'Velomine docs',
      description: 'How to run Velomine for yourself or your club.',
      defaultLocale: 'root',
      locales: {
        root: { label: 'English', lang: 'en' },
        it: { label: 'Italiano', lang: 'it' },
      },
      social: [{ icon: 'github', label: 'GitHub', href: 'https://github.com/zenkraker/Velomine' }],
      customCss: ['./src/styles/velomine.css'],
      sidebar: [
        {
          label: 'Overview',
          translations: { it: 'Panoramica' },
          items: ['quick-start'],
        },
        {
          label: 'Run it',
          translations: { it: 'Installazione' },
          items: ['self-hosting', 'configuration'],
        },
      ],
    }),
  ],
});
