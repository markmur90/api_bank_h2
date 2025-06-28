import os
import shutil
import subprocess
import ipaddress
import socket
import concurrent.futures
import argparse
from datetime import datetime

TOOLS_MAP={"1":"nc","2":"telnet","3":"ssh","4":"hydra","5":"medusa","6":"john","7":"hashcat","8":"ping","9":"nmap"}

def check_tools():
    missing=[t for t in TOOLS_MAP.values() if not shutil.which(t)]
    if missing:
        print(f"Faltan herramientas: {', '.join(missing)}")
        exit(1)

def scan_port(ip,port,selected,users_file,passwords_file):
    res={}
    try:
        with socket.socket() as s:
            s.settimeout(1)
            if s.connect_ex((ip,port))==0:
                res["status"]="abierto"
                for tool in selected:
                    cmd={
                        "nc":["nc","-zv",ip,str(port)],
                        "telnet":["telnet",ip,str(port)],
                        "ssh":["ssh","-o","BatchMode=yes",ip,"-p",str(port)],
                        "hydra":["hydra","-L",users_file,"-P",passwords_file,ip,"ssh","-s",str(port)],
                        "medusa":["medusa","-h",ip,"-U",users_file,"-P",passwords_file,"-M","ssh","-n",str(port)],
                        "john":["john",passwords_file,"--format=raw-md5","--show"],
                        "hashcat":["hashcat","-m","0",passwords_file,"--attack-mode","3"],
                        "ping":["ping","-c","4",ip],
                        "nmap":["nmap","-p",str(port),ip]
                    }.get(tool,[])
                    if cmd:
                        out=subprocess.run(cmd,capture_output=True,text=True).stdout.strip()
                        res[tool]=out
            else:
                res["status"]="cerrado"
    except Exception as e:
        res["error"]=str(e)
    return res

def scan_ip(ip,ports,selected,users_file,passwords_file):
    d={}
    for p in ports:
        d[p]=scan_port(ip,p,selected,users_file,passwords_file)
    return d

def scan_network(ip_range,port_range,users_file,passwords_file,selected,report_file):
    cache={}
    with open(report_file,"w") as rpt:
        ts=datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        rpt.write(f"Informe de escaneo - {ts}\n\n")
        all_ips=[str(ip) for net in ip_range for ip in net]
        with concurrent.futures.ThreadPoolExecutor(max_workers=20) as ex:
            futs={ex.submit(scan_ip,ip,port_range,selected,users_file,passwords_file):ip for ip in all_ips}
            for f in concurrent.futures.as_completed(futs):
                ip=futs[f]
                data=f.result()
                cache[ip]=data
                rpt.write(f"\n### REPORTE DE: {ip}\n")
                for port,tools in data.items():
                    rpt.write(f" Puerto {port}:\n")
                    for t,o in tools.items():
                        rpt.write(f"   {t}: {o}\n")
                rpt.write("\n" + "-"*50 + "\n")
        rpt.write("\nResumen:\n")
        for ip,data in cache.items():
            rpt.write(f"\nIP: {ip}\n")
            for port,tools in data.items():
                rpt.write(f" Puerto {port}:\n")
                for t,o in tools.items():
                    rpt.write(f"   {t}: {o}\n")

def main():
    check_tools()
    parser=argparse.ArgumentParser()
    parser.add_argument("ip_start")
    parser.add_argument("ip_end")
    parser.add_argument("port_start",type=int)
    parser.add_argument("port_end",type=int)
    parser.add_argument("users_file")
    parser.add_argument("passwords_file")
    parser.add_argument("selected_tools")
    args=parser.parse_args()
    ip_range=ipaddress.summarize_address_range(ipaddress.IPv4Address(args.ip_start),ipaddress.IPv4Address(args.ip_end))
    port_range=range(args.port_start,args.port_end+1)
    users_file=args.users_file
    passwords_file=args.passwords_file
    selected=[TOOLS_MAP[t] for t in args.selected_tools.split() if t in TOOLS_MAP]
    report_dir=os.path.join(os.path.dirname(__file__),"reports")
    os.makedirs(report_dir,exist_ok=True)
    ts=datetime.now().strftime("%Y%m%d_%H%M%S")
    report_file=os.path.join(report_dir,f"reporte_{ts}.txt")
    print(f"El informe se guardará en: {report_file}")
    scan_network(ip_range,port_range,users_file,passwords_file,selected,report_file)
    print(f"Escaneo completado. Informe guardado en: {report_file}")
    
if __name__=="__main__":
    main()
