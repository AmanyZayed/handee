package com.example.handee.unity

import android.app.Activity
import com.unity3d.player.IUnityPlayerLifecycleEvents
import com.unity3d.player.UnityPlayerForActivityOrService

class HandeeUnityPlayer(
    context: Activity,
    events: IUnityPlayerLifecycleEvents?,
) : UnityPlayerForActivityOrService(context, events)
