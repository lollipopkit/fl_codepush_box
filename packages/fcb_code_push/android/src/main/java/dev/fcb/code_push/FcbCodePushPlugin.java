package dev.fcb.code_push;

import android.content.Context;
import android.os.Build;
import androidx.annotation.NonNull;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.HashMap;
import java.util.Map;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public final class FcbCodePushPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {
  private MethodChannel channel;
  private Context applicationContext;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    applicationContext = binding.getApplicationContext();
    channel = new MethodChannel(binding.getBinaryMessenger(), "dev.fcb.code_push/paths");
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    if (channel != null) {
      channel.setMethodCallHandler(null);
      channel = null;
    }
    applicationContext = null;
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
    if (!"getPaths".equals(call.method)) {
      result.notImplemented();
      return;
    }
    if (applicationContext == null) {
      result.error("unavailable", "Android application context is unavailable", null);
      return;
    }

    File fcbCacheDir = new File(applicationContext.getCodeCacheDir(), "fcb");
    Map<String, String> paths = new HashMap<>();
    paths.put("cacheDir", fcbCacheDir.getAbsolutePath());

    String nativeLibraryDir = applicationContext.getApplicationInfo().nativeLibraryDir;
    if (nativeLibraryDir != null) {
      File libapp = new File(nativeLibraryDir, "libapp.so");
      if (libapp.isFile()) {
        paths.put("baselineArtifactPath", libapp.getAbsolutePath());
      }
    }
    if (!paths.containsKey("baselineArtifactPath")) {
      File extractedLibapp = extractBaselineLibapp(fcbCacheDir);
      if (extractedLibapp != null) {
        paths.put("baselineArtifactPath", extractedLibapp.getAbsolutePath());
      }
    }
    result.success(paths);
  }

  private File extractBaselineLibapp(File fcbCacheDir) {
    File baselineDir = new File(fcbCacheDir, "baseline");
    File output = new File(baselineDir, "libapp.so");
    if (output.isFile()) {
      return output;
    }

    String sourceApk = applicationContext.getApplicationInfo().sourceDir;
    if (sourceApk == null) {
      return null;
    }

    try (ZipFile zip = new ZipFile(sourceApk)) {
      for (String abi : Build.SUPPORTED_ABIS) {
        ZipEntry entry = zip.getEntry("lib/" + abi + "/libapp.so");
        if (entry == null) {
          continue;
        }
        if (!baselineDir.isDirectory() && !baselineDir.mkdirs()) {
          return null;
        }
        try (InputStream input = zip.getInputStream(entry);
             FileOutputStream outputStream = new FileOutputStream(output)) {
          byte[] buffer = new byte[8192];
          int read;
          while ((read = input.read(buffer)) != -1) {
            outputStream.write(buffer, 0, read);
          }
        }
        return output;
      }
    } catch (IOException ignored) {
      return null;
    }
    return null;
  }
}
