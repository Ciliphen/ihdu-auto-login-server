# iHDU 校园网自动登录脚本

本项目用于登录杭州电子科技大学 iHDU 校园网，并支持在 Linux/macOS 和 Windows 下通过定时任务自动检测网络状态、按需认证。

项目包含以下主要入口和辅助文件：

- `login.py`：执行一次校园网登录。
- `run.sh`：Linux/macOS 定时任务入口，适合配合 `cron` 使用。
- `run.ps1`：Windows PowerShell 入口，可手动运行。
- `run.bat`：Windows 批处理入口，推荐配合“任务计划程序”使用，已测试通过。
- `ihdu-auto-login.xml`：Windows 任务计划程序导入模板，已测试通过。

## 项目结构

```text
.
├── script/         # 登录逻辑实现
├── login.py        # 单次登录入口
├── run.sh          # Linux/macOS 定时任务入口
├── run.ps1         # Windows PowerShell 手动入口
├── run.bat         # Windows 批处理入口
├── ihdu-auto-login.xml # Windows 任务计划程序导入模板
└── logs/           # 按天生成的日志目录
```

## 运行依赖

- Python 3
- `requests`
- `curl`，仅 `run.sh` 需要
- PowerShell，Windows 自带即可运行 `run.ps1`，`run.bat` 也会调用它

如果缺少 Python 依赖，可以安装：

```bash
pip install requests
```

## 使用方式

### 1. 配置账号密码

编辑 `login.py`，填入自己的数字杭电账号和密码：

```python
lm.login(
    username="你的账号",
    password="你的密码"
)
```

如果这个仓库会同步到远程仓库，建议不要直接提交真实账号和密码。

### 2. 手动登录测试

Linux/macOS：

```bash
python3 login.py
```

Windows：

```powershell
python .\login.py
```

如果你的 Windows 使用 Python 启动器，也可以运行：

```powershell
py -3 .\login.py
```

## Linux/macOS 定时自动登录

推荐使用 `run.sh` 作为定时任务入口：

```bash
~/ihdu-login/run.sh
```

`run.sh` 的行为如下：

- 先检测当前网络是否已经可用。
- 若网络正常，则记录日志并跳过登录。
- 若网络不可用，则调用 `login.py` 执行认证。

### `crontab` 示例

每 5 分钟执行一次：

```cron
*/5 * * * * ~/ihdu-login/run.sh
```

查看当前 `crontab`：

```bash
crontab -l
```

编辑 `crontab`：

```bash
crontab -e
```

注意：如果你把项目放在其他目录，请把 `~/ihdu-login/run.sh` 修改成自己的实际脚本路径。若你修改了 Python 解释器路径，也请同步更新 `run.sh` 中调用 Python 的路径。

另外，`run.sh` 中执行登录的命令包含本机路径，使用前请改成你自己的 Python 解释器路径和项目路径：

```bash
/home/xilifeng/miniconda3/bin/python /home/xilifeng/ihdu-login/login.py
```

例如项目放在 `~/ihdu-login`，并且直接使用系统 `python3`，可以改成：

```bash
python3 ~/ihdu-login/login.py
```

## Windows 定时自动登录

Windows 下可以手动运行 `run.ps1`：

```powershell
powershell -ExecutionPolicy Bypass -File .\run.ps1
```

`run.ps1` 的行为如下：

- 先检测当前网络是否已经可用。
- 若网络正常，则记录日志并跳过登录。
- 若网络不可用，则调用同目录下的 `login.py` 执行认证。
- 优先使用 `python`，如果找不到会尝试使用 `py -3`。
- 日志会统一写入 `logs/` 目录。

**注意：PowerShell 方式的“任务计划程序”自动任务目前笔者没有测试成功，会出现闪退的情况，不知道为什么；Windows 自动任务推荐使用下面的 `run.bat` + `ihdu-auto-login.xml` 方案，这个方案已经测试通过。**

### 任务计划程序示例

如果想手动新建任务，推荐让任务计划程序直接执行 `run.bat`：

```text
程序或脚本：
D:\path\to\ihdu-auto-login\run.bat
```

请务必把上面的：

```text
D:\path\to\ihdu-auto-login\run.bat
```

修改成你电脑上真实的 `run.bat` 路径。例如本项目如果放在 `D:\Nonsynchronous\ihdu-auto-login`，则可以写成：

```text
D:\Nonsynchronous\ihdu-auto-login\run.bat
```

建议触发器设置为每 5 分钟或每 10 分钟执行一次，按自己的网络环境调整即可。

### 导入任务计划 XML

仓库中提供了 `ihdu-auto-login.xml`，推荐直接导入到 Windows“任务计划程序”中使用。这个 BAT 版本的计划任务已经测试通过。导入前请先编辑 XML 文件，把 `<Command>` 中的路径改成你电脑上真实的 `run.bat` 路径：

```xml
<Command>D:\Nonsynchronous\ihdu-auto-login\run.bat</Command>
```

如果你的项目放在其他目录，请改成对应路径，例如：

```xml
<Command>D:\path\to\ihdu-auto-login\run.bat</Command>
```

导入步骤：

1. 打开 Windows“任务计划程序”。
2. 在右侧选择“导入任务”。
3. 选择 `ihdu-auto-login.xml`。
4. 检查“操作”中的程序路径是否已经指向你的 `run.bat`。
5. 根据需要调整触发器时间、运行账户和是否隐藏运行。

当前 XML 模板包含一个触发器：每天 05:00 执行一次。你可以按自己的网络环境修改。

## 日志说明

脚本会自动将日志写入 `logs/` 目录，并按日期分类，例如：

```text
logs/2026-04-19.log
logs/2026-04-20.log
```

日志策略如下：

- 每天生成一个新的日志文件。
- 自动删除 30 天前的旧日志。
- `run.sh` 和 `run.ps1` 都会自行写日志，`run.bat` 会调用 `run.ps1` 写日志，定时任务中无需再额外使用重定向。

## 注意事项

- 请确保 `script` 目录与 `login.py` 位于同一个项目目录下。
- Windows 自动任务推荐使用 `run.bat` 或直接导入 `ihdu-auto-login.xml`；PowerShell 方式的计划任务目前没有测试成功。
- 如果使用 `ihdu-auto-login.xml` 导入任务计划，请先把 XML 里的 `<Command>` 改成你自己的 `run.bat` 实际路径。
- Linux/macOS 的 `crontab` 示例路径也必须改成你自己的 `run.sh` 实际路径。
- Linux/macOS 使用前还需要检查 `run.sh` 中调用 `login.py` 的命令，把 Python 和 `login.py` 路径改成自己的实际路径。
- `run.sh` 中的联网检测规则基于当前校园网环境测试通过。
- `run.ps1` 使用 Windows 常见连通性探测地址判断网络是否已经完成认证。

## 参考链接

- [HDU-srun-login-script](https://github.com/redchenjs/HDU-srun-login-script)
