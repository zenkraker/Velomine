{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
    // The first frame is on screen: put the brand splash away.
    const splash = document.getElementById('splash');
    if (splash) splash.remove();
  },
});
