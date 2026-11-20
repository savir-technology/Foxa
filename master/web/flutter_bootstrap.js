{{flutter_js}}
{{flutter_build_config}}

// Flutter keeps the entrypoint name stable. Bust only its cache while keeping
// CanvasKit and other large static assets cacheable.
for (const build of _flutter.buildConfig.builds) {
  if (build.mainJsPath) {
    build.mainJsPath += `?v=${Date.now()}`;
  }
}

_flutter.loader.load({
  config: {
    // Use the default CanvasKit GPU renderer.
  },
});
