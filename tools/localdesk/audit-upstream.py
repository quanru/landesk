#!/usr/bin/env python3
"""Record every RustDesk commit since the common ancestor, including deferred work.

Matching patch IDs, original commit references and port commit titles are separate
evidence types. A matching title records provenance, not full runtime equivalence.
This script does not mutate source, merge branches, push, build or release.
"""
import argparse
from collections import Counter
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[2]
FIRST = "f9586e171 41f182e63 55786aaa5 4b92080e3 f299fb990".split()
SECOND = """0cbeb0473 bd9262397 106f700be 01e1323e5 21c488b6c
3ec041644 68a35e65f c8a4e0680 8814503e0 851d2df88 e4b9594c5 e5bc204fe
4411d10f4 beeeef14f 182356ee8 25d274227 f7b0af78c 91c9fccbb 3202d1764 f96a44a01""".split()
THIRD = "b44b71cfa 092a961b6 dd9b21cf8".split()
FOURTH = "08affc69c 13e1278b4 5278fcab6 e9ddbd8f4".split()
SUPERSEDED = {"61f094499", "082a5a2a4", "291507664", "7c23fd307", "63822048d", "10bcf976f"}
RETIRED = {"c01300be2", "20ab5ab0a", "5b4d6baf4", "d6ea17006", "dabdbf73b",
           "4dd8e2039", "7eb915011", "594e63805", "9f9585ce1", "d4ac2c07b",
           "e614de83f", "29d1ab26a"}
PRIORITY = {"08affc69c", "b44b71cfa", "092a961b6", "dd9b21cf8", "13e1278b4",
            "5278fcab6", "e9ddbd8f4", "f705902ec", "2b6fedfc8", "402ed07b0"}


def git(*args):
    return subprocess.check_output(["git", *args], cwd=ROOT, text=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--upstream", default="refs/remotes/rustdesk/master")
    parser.add_argument("--output", default="docs/validation/rustdesk-upstream-audit-2026-11-04.md")
    parser.add_argument("--pending-current-batch", action="store_true",
                        help="Include the current manually reviewed, uncommitted batch")
    args = parser.parse_args()
    upstream = git("rev-parse", args.upstream).strip()
    head = git("rev-parse", "HEAD").strip()
    base = git("merge-base", head, upstream).strip()
    own = [line.split("\t", 1) for line in git("log", "--format=%H%x09%s", f"{base}..{head}").splitlines()]
    bodies = git("log", "--format=%H%n%B", f"{base}..{head}")
    patch_matches = {line.split()[1] for line in git("cherry", head, upstream).splitlines() if line.startswith("-")}
    entries = []
    commits = git("log", "--reverse", "--format=%H%x09%s", f"{base}..{upstream}").splitlines()
    for line in commits:
        sha, title = line.split("\t", 1)
        short = sha[:9]
        paths = git("diff-tree", "--no-commit-id", "--name-only", "-r", sha).splitlines()
        ports = [h for h, subject in own if subject == title and len(title) > 20]
        if (short in FIRST or short in SECOND or short in THIRD or short in FOURTH) and (short in bodies or args.pending_current_batch):
            status = "本次接入"
            reason = "首批 5 项" if short in FIRST else "第二批 20 项" if short in SECOND else "第三批 3 项" if short in THIRD else "第四批 4 项"
            if short in FOURTH:
                reason += {
                    "08affc69c": "；文件剪贴板范围／列表绑定与 Windows 坐标溢出；Mac 组件通过，Windows 原生待验",
                    "13e1278b4": "；适配 LAN 能力协商及空闲字段 36；无能力或查询失败时不自动输入密码",
                    "5278fcab6": "；有界解压与游标尺寸／热点校验，保留 LanDesk 旋转；Mac 测试通过，其他宿主待验",
                    "e9ddbd8f4": "；内容去重、字节事件与 Flutter 解码缓存回收／重放；不宣称所有会话存储均有界",
                }[short]
            elif short == "91c9fccbb":
                reason += "；仅 bytes/crossbeam-epoch，未恢复已移除的 quinn"
            elif short == "182356ee8":
                reason += "；适配 LAN 最近设备／收藏，未恢复云地址簿"
            elif short == "b44b71cfa":
                reason += "；下载目标、覆盖确认、续传和空目录校验，适配本地目标平台规则"
            elif short == "092a961b6":
                reason += "；适配 LAN 握手前连接名额、登录期限和多监听器 ID 隔离"
            elif short == "dd9b21cf8":
                reason += "；认证前 128 KiB 帧限制，禁止登录前发送剪贴板广播"
        elif sha in patch_matches:
            status, reason = "已有等价补丁", "git cherry / stable patch ID 匹配；不是缺失提交"
        elif ports:
            status = "已有移植记录"
            reason = f"本地 `{ports[0][:9]}` 同题移植；后续分歧仍须分别核对"
        elif short in bodies:
            status, reason = "已有移植记录", "本地提交说明引用原始 SHA；不据此宣称逐行或运行时完全相同"
        elif short in SUPERSEDED:
            status, reason = "上游撤回／替代", "原修改与回退不成对重放；采用当前分支的后续实现"
        elif short == "0d6265bb2":
            status, reason = "已有对应实现", "AppDelegate 已用 FlutterImplicitEngineDelegate，Info.plist 已配置 SceneDelegate"
        elif short in {"d1da05c4d", "7aa98d43c"}:
            status, reason = "已有对应实现", "LanDesk 已删除插件运行时和入口，保留自己的残留门禁"
        elif all(p.startswith(("docs/", "src/lang/", ".github/", "flutter/android/fastlane/", "fastlane/"))
                 or p.lower().endswith(".md") for p in paths):
            status, reason = "本轮不接入", "上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程"
        elif short in RETIRED or re.search(r"webrtc|websocket|rendezvous|oidc|address.book|API server|ID server|hbbs|online state|custom client|feat\(update\)|update.*metadata|silent auto.update", title, re.I):
            status, reason = "不适用于现有流程", "涉及已移除的公网／云账号／更新／旧 UI 或原版 ID 认证路径；不机械恢复"
        else:
            status = "优先待移植" if short in PRIORITY else "暂缓，未宣称同步"
            if short in {"402ed07b0", "f705902ec", "2b6fedfc8"}:
                reason = "Windows 安装器脚本／提权交接／服务控制加固；需保留 LanDesk 品牌并验证标准用户、管理员和特殊字符路径，Mac 检查不能替代"
            elif short in PRIORITY:
                reason = "安全相关；需适配现有 LAN 协议／文件传输／输入实现并完成目标平台验证"
            elif any(p.startswith("flutter/") for p in paths):
                reason = "涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证"
            elif any(p.startswith(("res/vcpkg/", "appimage/", "res/msi/")) for p in paths):
                reason = "安装器／原生依赖／打包修改；需对应平台构建，不能只复制补丁就宣称生效"
            elif any(p in {"Cargo.lock", "Cargo.toml", "libs/hbb_common"} for p in paths):
                reason = "依赖／特性或子模块关联；保留固定 LAN fork，需另做依赖闭包与平台构建验证"
            else:
                reason = "相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态"
        entries.append((sha, title, status, reason))

    counts = Counter(e[2] for e in entries)
    lines = ["# RustDesk 上游逐提交清单", "", f"核对版本：`{upstream}`；LanDesk 对照 HEAD：`{head}`；共同祖先：`{base}`。",
             "", "本清单覆盖共同祖先之后 RustDesk 的全部提交。分组是接入决策和后续队列，不能把‘暂缓’理解为已合入，也不能把 SHA 不同都算成功能缺失。",
             "已有移植记录按提交标题或原 SHA 引用追溯，证据强度低于补丁等价；不代表完整安全审计或全端运行验收。",
             "", "| 状态 | 提交数 |", "| --- | ---: |"]
    lines += [f"| {status} | {count} |" for status, count in sorted(counts.items())]
    lines += [f"| 合计 | {len(entries)} |", "", "## 优先队列", "",
              "以下只列尚未接入的安全优先项；已接入项的平台验证边界见第四批验证记录。不能只凭本清单声称风险已消除。",
              *[f"- [`{sha[:9]}`](https://github.com/rustdesk/rustdesk/commit/{sha})：{title}" for sha, title, status, reason in entries if status == "优先待移植"],
              "", "## 全部提交", "", "| RustDesk 提交 | 标题 | 状态 | 依据／处理范围 |", "| --- | --- | --- | --- |"]
    for sha, title, status, reason in entries:
        lines.append(f"| [`{sha[:9]}`](https://github.com/rustdesk/rustdesk/commit/{sha}) | {title.replace('|', '/')} | {status} | {reason} |")
    (ROOT / args.output).write_text("\n".join(lines) + "\n")
    print(dict(counts))
    print(f"Recorded {len(entries)} commits in {args.output}")


if __name__ == "__main__":
    main()
