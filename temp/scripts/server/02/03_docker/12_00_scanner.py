# scanner.py
import argparse,os,datetime,json,nmap,requests

def scan_ip(ip):
    nm=nmap.PortScanner()
    nm.scan(ip,arguments='-sV')
    return nm[ip]['tcp'] if 'tcp' in nm[ip] else {}
  
def query_vulners(product,version):
    q=f'{product} {version}'
    url='https://vulners.com/api/v3/search/lucene/'
    r=requests.post(url,json={'query':q})
    data=r.json()
    return data.get('data',{}).get('search',[])
  
def generate_report(ip,scan_data):
    now=datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
    folder=f'reports/{ip}_{now}'
    os.makedirs(folder,exist_ok=True)
    report={'ip':ip,'timestamp':now,'services':[]}
    for port,info in scan_data.items():
        svc=info.get('name','')+' '+info.get('product','')+' '+info.get('version','')
        vulns=query_vulners(info.get('product',''),info.get('version',''))
        report['services'].append({'port':port,'service':svc,'vulnerabilities':vulns})
    path=f'{folder}/report.json'
    with open(path,'w') as f:json.dump(report,f,indent=2)
    print(f'Informe guardado en {path}')
    
if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('ip')
    args=parser.parse_args()
    sd=scan_ip(args.ip)
    generate_report(args.ip,sd)
