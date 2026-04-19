# iHDU 校园网自动登录脚本

本项目用于登录杭州电子科技大学 iHDU 校园网，并支持通过 `cron` 定时执行自动认证。

项目包含两个主要入口：

- `login.py`：执行一次校园网登录
- `run.sh`：先检测当前网络状态，再按需调用 `login.py`，适合配合 `cron` 使用

## 项目结构

```text
.
├── script/         # 登录逻辑实现
├── login.py        # 单次登录入口
├── run.sh          # 定时任务入口
└── logs/           # 按天生成的日志目录
```

## 运行依赖

- Python 3
- `requests`
- `curl`

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

执行以下命令测试是否可以正常登录：

```bash
python3 login.py
```

## 定时自动登录

推荐使用 `run.sh` 作为定时任务入口：

```bash
~/ihdu-login/run.sh
```

`run.sh` 的行为如下：

- 先检测当前网络是否已经可用
- 若网络正常，则记录日志并跳过登录
- 若网络不可用，则调用 `login.py` 执行认证

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

## 日志说明

脚本会自动将日志写入 `logs/` 目录，并按日期分类，例如：

```text
logs/2026-04-19.log
logs/2026-04-20.log
```

日志策略如下：

- 每天生成一个新的日志文件
- 自动删除 30 天前的旧日志
- `cron` 中无需再额外使用 `>> log.txt 2>&1` 重定向

## 注意事项

- 请确保 `script` 目录与 `login.py` 位于同一项目目录下
- 若你修改了 Python 解释器路径，请同步更新 `run.sh` 中的解释器路径
- `run.sh` 中的联网检测规则基于当前校园网环境测试通过

## 参考链接

- [HDU-srun-login-script](https://github.com/redchenjs/HDU-srun-login-script)
