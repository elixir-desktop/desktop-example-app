package io.elixirdesktop.example

import android.annotation.SuppressLint
import android.app.PendingIntent
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Message
import android.system.Os
import android.util.Log
import android.webkit.WebChromeClient
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import org.json.JSONArray
import org.json.JSONObject
import java.net.ServerSocket
import kotlin.concurrent.thread
import java.io.*
import java.util.*
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.locks.ReentrantLock
import java.util.zip.ZipInputStream


class Bridge(private val applicationContext : Context, private var webview : WebView) {
    private val server = ServerSocket(0)
    private var lastURL = String()
    private val assets = applicationContext.assets.list("")
    private var writers = ArrayList<DataOutputStream>()
    private val writerLock = ReentrantLock()

    class Notification {
        var title = String()
        var message = String()
        var callback = 0uL
        var pid = JSONObject()
        var obj = JSONArray()
    }

    private val notifications = ConcurrentHashMap<ULong, Notification>()

    init {
        Os.setenv("ELIXIR_DESKTOP_OS", "android", false)
        Os.setenv("BRIDGE_PORT", server.localPort.toString(), false)
        // not really the home directory, but persistent between app upgrades
        Os.setenv("HOME", applicationContext.filesDir.absolutePath, false)

        setWebView(webview)

        thread(start = true) {
            while (true) {
                val socket = server.accept()
                socket.tcpNoDelay = true
                println("Client connected: ${socket.inetAddress.hostAddress}")
                thread {
                    val reader = DataInputStream(BufferedInputStream((socket.getInputStream())))
                    val writer = DataOutputStream(socket.getOutputStream())
                    writerLock.lock()
                    writers.add(writer)
                    writerLock.unlock()
                    try {
                        handle(reader, writer)
                    } catch(e : EOFException) {
                        println("Client disconnected: ${socket.inetAddress.hostAddress}")
                        socket.close()
                    }
                    writerLock.lock()
                    writers.remove(writer)
                    writerLock.unlock()
                }
            }
        }

        // The possible values are armeabi, armeabi-v7a, arm64-v8a, x86, x86_64, mips, mips64.
        var prefix = ""
        for (abi in Build.SUPPORTED_ABIS) {
            when (abi) {
                "arm64-v8a", "armeabi-v7a", "x86_64" -> {
                    prefix = abi
                    break
                }
                "armeabi" -> {
                    prefix = "armeabi-v7a"
                    break
                }
                else -> continue
            }
        }

        if (prefix == "") {
            throw Exception("Could not find any supported ABI")
        }

        val runtime = "$prefix-runtime"
        Log.d("RUNTIME", runtime)

        thread(start = true) {
            val packageInfo = applicationContext.packageManager
                .getPackageInfo(applicationContext.packageName, 0)

            val nativeDir = packageInfo.applicationInfo.nativeLibraryDir
            val lastUpdateTime = (packageInfo.lastUpdateTime / 1000).toString()

            val releaseDir = applicationContext.filesDir.absolutePath + "/app"
            val doneFile = File("$releaseDir/done")

            // Delete old build if new is installed
            if (doneFile.exists() && doneFile.readText() != lastUpdateTime) {
                File(releaseDir).deleteRecursively()
            }

            // Cleaning deprecated build-xxx folders
            for (file in applicationContext.filesDir.list()!!) {
                if (file.startsWith("build-")) {
                    File(applicationContext.filesDir.absolutePath + "/" + file).deleteRecursively()
                }
            }

            val binDir = "$releaseDir/bin"

            Os.setenv("UPDATE_DIR", "$releaseDir/update/", false)
            Os.setenv("BINDIR", binDir, false)
            Os.setenv("LIBERLANG", "$nativeDir/liberlang.so", false)

            if (!doneFile.exists()) {
                File(binDir).mkdirs()
                if (unpackAsset(releaseDir, "app") &&
                        unpackAsset(releaseDir, runtime)) {
                    for (lib in File("$releaseDir/lib").list()!!) {
                        val parts = lib.split("-")
                        val name = parts[0]

                        val nif = "$prefix-nif-$name"
                        unpackAsset("$releaseDir/lib/$lib/priv", nif)
                    }

                    doneFile.writeText(lastUpdateTime)
                }
            }

            if (!doneFile.exists()) {
                Log.e("ERROR", "Failed to extract runtime")
                throw Exception("Failed to extract runtime")
            }

            // Creating symlinks for binaries
            // Re-creating even on relaunch because we can't
            // be sure of the native libs directory
            // https://github.com/JeromeDeBretagne/erlanglauncher/issues/2
            for (file in File(nativeDir).list()!!) {
                if (file.startsWith("lib__")) {
                    var name = File(file).name
                    name = name.substring(5, name.length - 3)
                    Log.d("BIN", "$nativeDir/$file -> $binDir/$name")
                    File("$binDir/$name").delete()
                    Os.symlink("$nativeDir/$file", "$binDir/$name")
                }
            }

            var logdir = applicationContext.getExternalFilesDir("")?.path
            if (logdir == null) {
                logdir = applicationContext.filesDir.absolutePath
            }
            Os.setenv("LOG_DIR", logdir!!, true)
            Log.d("ERLANG", "Starting beam...")
            val ret = startErlang(releaseDir, logdir)
            Log.d("ERLANG", ret)
            if (ret != "ok") {
                throw Exception(ret)
            }
        }
    }


    private fun unpackAsset(releaseDir: String, assetName: String): Boolean {
        assets!!
        //if (assets.contains("$assetName.zip.xz")) {
        //    val input = BufferedInputStream(applicationContext.assets.open("$assetName.zip.xz"))
        //    return unpackZip(releaseDir, XZInputStream(input))
        //}
        if (assets.contains("$assetName.zip")) {
            val input = BufferedInputStream(applicationContext.assets.open("$assetName.zip"))
            return unpackZip(releaseDir, input)
        }
        return false
    }

    private fun unpackZip(releaseDir: String, inputStream: InputStream): Boolean {
        Log.d("RELEASEDIR", releaseDir)
        File(releaseDir).mkdirs()
        try
        {
            val zis = ZipInputStream(BufferedInputStream(inputStream))
            val buffer = ByteArray(1024)

            var ze =  zis.nextEntry
            while (ze != null)
            {
                val filename = ze.name

                // Need to create directories if not exists, or
                // it will generate an Exception...
                val fullpath = "$releaseDir/$filename"
                if (ze.isDirectory) {
                    Log.d("DIR", fullpath)
                    File(fullpath).mkdirs()
                    zis.closeEntry()
                    ze =  zis.nextEntry
                    continue
                }

                Log.d("FILE", fullpath)
                val fout = FileOutputStream(fullpath)
                var count = zis.read(buffer)
                while (count != -1) {
                    fout.write(buffer, 0, count)
                    count = zis.read(buffer)
                }

                fout.close()
                zis.closeEntry()
                ze = zis.nextEntry
            }

            zis.close()
        }
        catch(e: IOException)
        {
            e.printStackTrace()
            return false
        }

        return true
    }

    @SuppressLint("SetJavaScriptEnabled")
    fun setWebView(_webview: WebView) {
        webview = _webview
        webview.webChromeClient = object : WebChromeClient() {
            override fun onCreateWindow(
                view: WebView?,
                isDialog: Boolean,
                isUserGesture: Boolean,
                resultMsg: Message?
            ): Boolean {
                val newWebView = WebView(applicationContext)
                view?.addView(newWebView)
                val transport = resultMsg?.obj as WebView.WebViewTransport

                transport.webView = newWebView
                resultMsg.sendToTarget()

                newWebView.webViewClient = object : WebViewClient() {
                    @Deprecated("Deprecated in Java")
                    override fun shouldOverrideUrlLoading(view: WebView, url: String): Boolean {
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        applicationContext.startActivity(intent)
                        return true
                    }
                }
                return true
            }
        }

        val settings = webview.settings
        settings.setSupportMultipleWindows(true)
        settings.javaScriptEnabled = true
        settings.layoutAlgorithm = WebSettings.LayoutAlgorithm.NORMAL
        settings.useWideViewPort = true
        // enable Web Storage: localStorage, sessionStorage
        settings.domStorageEnabled = true
        // webview.webViewClient = WebViewClient()
        if (lastURL.isNotBlank()) {
            webview.post { webview.loadUrl(lastURL) }
        }
    }


    fun getLocalPort(): Int {
        return server.localPort
    }

    private fun handle(reader : DataInputStream, writer : DataOutputStream) {
        val ref = ByteArray(8)

        while (true) {
            val length = reader.readInt()
            reader.readFully(ref)
            val data = ByteArray(length - ref.size)
            reader.readFully(data)

            val json = JSONArray(String(data))

            val module = json.getString(0)
            val method = json.getString(1)
            val args = json.getJSONArray(2)

            if (method == ":loadURL") {
                lastURL = args.getString(1)
                webview.post { webview.loadUrl(lastURL) }

            }
            if (method == ":launchDefaultBrowser") {
                val uri = Uri.parse(args.getString(0))
                if (uri.scheme == "http") {
                    val browserIntent = Intent(Intent.ACTION_VIEW, uri)
                    applicationContext.startActivity(browserIntent)
                } else if (uri.scheme == "file") {
                    openFile(uri.path)
                }
            }

            var response = ref
            response += when (method) {
                ":getOsDescription" -> {
                    val info = "Android ${Build.DEVICE} ${Build.BRAND} ${Build.VERSION.BASE_OS} ${
                        Build.SUPPORTED_ABIS.joinToString(",")
                    }"
                    stringToList(info).toByteArray()
                }
                ":getCanonicalName" -> {
                    val primaryLocale = getCurrentLocale(applicationContext)
                    val locale = "${primaryLocale.language}_${primaryLocale.country}"
                    stringToList(locale).toByteArray()

                }
                else -> {
                    "use_mock".toByteArray()
                }
            }
            writerLock.lock()
            writer.writeInt(response.size)
            writer.write(response)
            writerLock.unlock()        }
    }

    fun sendMessage(message : ByteArray) {
        thread {
            writerLock.lock()
            while (writers.isEmpty()) {
                writerLock.unlock()
                Thread.sleep(100)
                writerLock.lock()
            }
            for (writer in writers) {
                writer.writeInt(message.size)
                writer.write(message)
            }
            writerLock.unlock()
        }
    }

    private fun getCurrentLocale(context: Context): Locale {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            context.resources.configuration.locales[0]
        } else {
            context.resources.configuration.locale
        }
    }

    private fun openFile(filename: String?) {
        // Get URI and MIME type of file
        val file = File(filename)
        val uri =
            FileProvider.getUriForFile(applicationContext, applicationContext.packageName + ".fileprovider", File(filename))

        val mime: String? = if (file.isDirectory) {
            "resource/folder"
        } else {
            applicationContext.contentResolver.getType(uri)
        }

        // Open file with user selected app
        var intent = Intent()
        intent.action = Intent.ACTION_VIEW
        intent.setDataAndType(uri, mime)
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        intent.addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
        intent = Intent.createChooser(intent, "")
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            applicationContext.startActivity(intent)
        } catch (e : ActivityNotFoundException) {
            Log.d("Exception", e.toString())
        }
    }

    private fun stringToList(str : String): String {
        val numbers = str.toByteArray().map { it.toInt().toString() }
        return "[${numbers.joinToString(",")}]"
    }

    private fun listToString(raw : JSONArray): String {
        var title = ""
        for (i in 0 until raw.length()) {
            title += raw.getInt(i).toChar()
        }
        return title
    }

    private fun getKeyword(keywords: JSONArray, searchKey : String) : Any {
        for (i in 0 until keywords.length()) {
            val tupleValues = keywords.getJSONObject(i).getJSONArray(":value")
            val key = tupleValues.getString(0)
            if (key == searchKey) return tupleValues.get(1)
        }
        return ""
    }

    /**
     * A native method that is implemented by the 'native-lib' native library,
     * which is packaged with this application.
     */
    private external fun startErlang(releaseDir: String, logdir: String): String

    companion object {
        // Used to load the 'native-lib' library on application startup.
        init {
            System.loadLibrary("native-lib")
        }
    }
}
