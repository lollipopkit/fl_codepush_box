package dev.fcb.code_push;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.HashMap;
import java.util.Map;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public final class FcbCodePushPlugin implements FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler {
  private MethodChannel channel;
  private Context applicationContext;
  @Nullable private Activity activity;

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
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    activity = binding.getActivity();
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    activity = null;
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    activity = binding.getActivity();
  }

  @Override
  public void onDetachedFromActivity() {
    activity = null;
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
    if ("restart".equals(call.method)) {
      restartApp(result);
      return;
    }
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

  private void restartApp(@NonNull MethodChannel.Result result) {
    Context ctx = activity != null ? activity : applicationContext;
    if (ctx == null) {
      result.error("unavailable", "No context available for restart", null);
      return;
    }
    result.success(null);
    Intent intent = ctx.getPackageManager().getLaunchIntentForPackage(ctx.getPackageName());
    if (intent != null) {
      intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_NEW_TASK);
      ctx.startActivity(intent);
    }
    android.os.Process.killProcess(android.os.Process.myPid());
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
