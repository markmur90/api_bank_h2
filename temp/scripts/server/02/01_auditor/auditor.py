# auditor.py
import argparse,json

def load_report(path):
    with open(path) as f:return json.load(f)
    
def summarize(vulns,level):
    filtered=[v for v in vulns if v.get('severity','').lower()==level.lower()]
    print(f'Vulnerabilidades nivel {level}: {len(filtered)}')
    for v in filtered:print(f"{v.get('id')} {v.get('title')} refs:{','.join(v.get('references',[]))}")
    
if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('report_path')
    parser.add_argument('--level',default='critical')
    args=parser.parse_args()
    rpt=load_report(args.report_path)
    allv=[v for svc in rpt['services'] for v in svc['vulnerabilities']]
    summarize(allv,args.level)
