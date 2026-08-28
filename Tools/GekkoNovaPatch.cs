using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Text;
using BepInEx;
using HarmonyLib;
using UnityEngine;
using UnityEngine.UI;

namespace GekkoNovaPatch
{
    [BepInPlugin("local.gekko.nova.zh", "Gekko Episode of Nova Chinese", "0.1.0")]
    public sealed class Plugin : BaseUnityPlugin
    {
        internal static readonly Dictionary<string, string> Translations = new Dictionary<string, string>(StringComparer.Ordinal);
        internal static Font ChineseFont;
        private Harmony _harmony;
        private float _nextFontScan;

        private void Awake()
        {
            LoadTranslations();
            _harmony = new Harmony("local.gekko.nova.zh");
            _harmony.PatchAll(typeof(Plugin).Assembly);
            PatchCustomTextSetters();
            Logger.LogInfo("Loaded " + Translations.Count + " Chinese text entries");
        }

        private void PatchCustomTextSetters()
        {
            var prefix = new HarmonyMethod(typeof(Plugin).GetMethod("TranslateTextArgument", BindingFlags.Static | BindingFlags.NonPublic));
            var patched = new HashSet<MethodBase>();
            patched.Add(AccessTools.PropertySetter(typeof(Text), "text"));
            foreach (var typeName in new[]
            {
                "Utage.UguiNovelText", "Utage.NovelText", "NovelText",
                "TMPro.TMP_Text", "TMPro.TextMeshProUGUI"
            })
            {
                var type = AccessTools.TypeByName(typeName);
                if (type == null) continue;
                var setter = AccessTools.Method(type, "set_Text") ?? AccessTools.Method(type, "set_text");
                if (setter == null || patched.Contains(setter)) continue;
                var parameters = setter.GetParameters();
                if (parameters.Length != 1 || parameters[0].ParameterType != typeof(string)) continue;
                try
                {
                    _harmony.Patch(setter, prefix: prefix);
                    patched.Add(setter);
                    Logger.LogInfo("Patched text setter: " + type.FullName + "." + setter.Name);
                }
                catch (Exception ex)
                {
                    Logger.LogWarning("Could not patch " + type.FullName + ": " + ex.Message);
                }
            }
        }

        private static void TranslateTextArgument(ref string value)
        {
            if (string.IsNullOrEmpty(value)) return;
            string translated;
            if (Translations.TryGetValue(value, out translated) && translated != value) value = translated;
        }

        private void Update()
        {
            if (Time.unscaledTime < _nextFontScan) return;
            _nextFontScan = Time.unscaledTime + 2f;
            EnsureChineseFont();
            if (ChineseFont == null) return;
            foreach (var text in Resources.FindObjectsOfTypeAll<Text>())
            {
                if (text != null && text.font != ChineseFont && ContainsCjk(text.text)) text.font = ChineseFont;
            }
        }

        private void LoadTranslations()
        {
            var paths = Directory.Exists(Paths.PluginPath) ? Directory.GetFiles(Paths.PluginPath, "GekkoNova_*.tsv") : new string[0];
            foreach (var path in paths)
            {
                foreach (var raw in File.ReadAllLines(path, Encoding.UTF8))
                {
                    if (string.IsNullOrWhiteSpace(raw) || raw.StartsWith("#")) continue;
                    var split = raw.Split(new[] { '\t' }, 2);
                    if (split.Length != 2 || split[0].Length == 0) continue;
                    Translations[Unescape(split[0])] = Unescape(split[1]);
                }
            }
        }

        private static string Unescape(string value)
        {
            return value.Replace("\\r", "\r").Replace("\\n", "\n").Replace("\\t", "\t").Replace("\\\\", "\\");
        }

        private static bool ContainsCjk(string value)
        {
            if (string.IsNullOrEmpty(value)) return false;
            foreach (var c in value) if ((c >= '\u3040' && c <= '\u30ff') || (c >= '\u3400' && c <= '\u9fff')) return true;
            return false;
        }

        internal static void EnsureChineseFont()
        {
            if (ChineseFont != null) return;
            try
            {
                ChineseFont = Font.CreateDynamicFontFromOSFont(new[] { "Microsoft YaHei UI", "Microsoft YaHei", "SimSun", "Arial" }, 32);
            }
            catch (Exception ex) { Debug.LogWarning("Could not create Chinese font: " + ex.Message); }
        }

        [HarmonyPatch(typeof(Text), "set_text")]
        private static class TextSetterPatch
        {
            private static void Prefix(ref string value)
            {
                TranslateTextArgument(ref value);
            }
        }
    }
}
