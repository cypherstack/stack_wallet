package com.cypherstack.accessibility_probe

import android.accessibilityservice.AccessibilityService
import android.app.Activity
import android.app.Application
import android.content.BroadcastReceiver
import android.content.Context
import android.os.Handler
import android.os.Looper
import java.io.File
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import java.util.concurrent.CopyOnWriteArrayList

abstract class ProbeService : AccessibilityService() {
    val events = CopyOnWriteArrayList<String>()
    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        events.add((event.text + listOf(event.beforeText, event.contentDescription)).joinToString(" "))
    }
    override fun onInterrupt() {}
    fun tree(): String {
        val result = StringBuilder()
        fun visit(node: AccessibilityNodeInfo?, depth: Int) {
            if (node == null || depth > 50) return
            result.append(node.text).append(' ').append(node.contentDescription).append('\n')
            for (i in 0 until node.childCount) visit(node.getChild(i), depth + 1)
            node.recycle()
        }
        visit(rootInActiveWindow, 0)
        return result.toString()
    }
}
class ToolProbeService : ProbeService() {
    companion object { @Volatile var instance: ToolProbeService? = null }
    override fun onServiceConnected() { instance = this }
    override fun onDestroy() { instance = null; super.onDestroy() }
}
class NonToolProbeService : ProbeService() {
    companion object { @Volatile var instance: NonToolProbeService? = null }
    override fun onServiceConnected() { instance = this }
    override fun onDestroy() { instance = null; super.onDestroy() }
}
class ProbeApplication : Application(), Application.ActivityLifecycleCallbacks {
    companion object { @Volatile var activity: Activity? = null }
    override fun onCreate() { super.onCreate(); registerActivityLifecycleCallbacks(this) }
    override fun onActivityCreated(value: Activity, state: Bundle?) { activity = value }
    override fun onActivityResumed(value: Activity) { activity = value }
    override fun onActivityStarted(value: Activity) {}
    override fun onActivityPaused(value: Activity) {}
    override fun onActivityStopped(value: Activity) {}
    override fun onActivitySaveInstanceState(value: Activity, state: Bundle) {}
    override fun onActivityDestroyed(value: Activity) { if (activity === value) activity = null }
}
class ProbeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val pending = goAsync()
        Thread {
            val result = File(context.filesDir, "accessibility-result.txt")
            try {
                ProbeChecks(intent.getStringExtra("scope") ?: "host").run()
                result.writeText("PASS: node queries and text events, before/after activity recreation")
            } catch (error: Throwable) {
                result.writeText("FAIL: ${error.stackTraceToString()}")
            } finally { pending.finish() }
        }.start()
    }
}
class ProbeChecks(private val scope: String) {
    private fun await(message: String, predicate: () -> Boolean) {
        val deadline = System.currentTimeMillis() + 20000
        while (System.currentTimeMillis() < deadline) {
            if (predicate()) return
            Thread.sleep(100)
        }
        error(message)
    }
    fun run() {
        await("Both test accessibility services must be enabled") {
            ToolProbeService.instance != null && NonToolProbeService.instance != null
        }
        checkPhase("initial")
        val activity = ProbeApplication.activity ?: error("No probe activity")
        Handler(Looper.getMainLooper()).post { activity.recreate() }
        await("Activity did not recreate") {
            ProbeApplication.activity != null && ProbeApplication.activity !== activity
        }
        checkPhase("recreated")
    }
    private fun checkPhase(phase: String) {
        val tool = ToolProbeService.instance!!
        val nonTool = NonToolProbeService.instance!!
        val protected = Build.VERSION.SDK_INT >= 34 && scope != "none"
        await("$phase: tool cannot read the seed/input") {
            val tree = tool.tree()
            tree.contains("seed-probe") && tree.contains("private-probe") && tree.contains("public-probe")
        }
        if (protected) check(nonTool.events.none { it.contains("private-probe") || it.contains("seed-probe") }) {
            "$phase: non-tool received a secret during startup or recreation"
        }
        tool.events.clear()
        nonTool.events.clear()
        await("$phase: no positive-control input events for tool") {
            tool.events.any { it.contains("private-probe") }
        }
        repeat(20) {
            val tree = nonTool.tree()
            if (protected) {
                check(!tree.contains("seed-probe") && !tree.contains("private-probe")) {
                    "$phase: non-tool can query secrets"
                }
                check(nonTool.events.none { it.contains("private-probe") || it.contains("seed-probe") }) {
                    "$phase: non-tool received secret events"
                }
            } else {
                check(tree.contains("seed-probe") && tree.contains("private-probe")) {
                    "$phase: baseline/older-API positive control failed"
                }
            }
            Thread.sleep(100)
        }
        if (!protected) check(nonTool.events.any { it.contains("private-probe") }) {
            "$phase: baseline/older-API event positive control failed"
        }
    }
}
