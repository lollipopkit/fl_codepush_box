package dev.fcb.code_push;

import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

import java.io.File;

public final class FcbCodePushPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {
  private MethodChannel channel;
  private FlutterPluginBinding binding;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    this.binding = binding;
    channel = new MethodChannel(binding.getBinaryMessenger(), "dev.fcb.code_push/android_paths");
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    if (channel != null) {
      channel.setMethodCallHandler(null);
      channel = null;
    }
    this.binding = null;
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
    if (binding == null) {
      result.error("unavailable", "FCB plugin is not attached to an engine", null);
      return;
    }
    switch (call.method) {
      case "getCacheDir":
        result.success(binding.getApplicationContext().getCacheDir().getAbsolutePath());
        break;
      case "getBaselineArtifactPath":
        String nativeLibraryDir =
            binding.getApplicationContext().getApplicationInfo().nativeLibraryDir;
        result.success(new File(nativeLibraryDir, "libapp.so").getAbsolutePath());
        break;
      default:
        result.notImplemented();
        break;
    }
  }
}
