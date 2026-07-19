#!/usr/bin/env python3
import os
import re
import urllib.request
import urllib.json
import json
import sys

REPO = "jaakkokorhonen/pwa-oura"
ISSUES_FILE = "ISSUES.md"

def parse_issues(filename):
    with open(filename, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Split content by "### Issue "
    chunks = content.split("### Issue ")
    issues = []
    
    for chunk in chunks[1:]:
        lines = chunk.strip().split('\n')
        if not lines:
            continue
        title_line = lines[0].strip()
        body = '\n'.join(lines[1:]).strip()
        issues.append({
            "title": f"Issue: {title_line}",
            "body": body
        })
    return issues

def create_github_issue(token, repo, title, body):
    url = f"https://api.github.com/repos/{repo}/issues"
    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github.v3+json",
        "User-Agent": "Antigravity-PWA-Oura-Script"
    }
    data = json.dumps({"title": title, "body": body}).encode('utf-8')
    req = urllib.request.Request(url, data=data, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req) as res:
            if res.status == 201:
                print(f"✓ Luotu onnistuneesti: {title}")
                return True
    except Exception as e:
        print(f"✗ Virhe luotaessa '{title}': {e}")
        return False

def main():
    if not os.path.exists(ISSUES_FILE):
        print(f"Virhe: {ISSUES_FILE} ei löydy.")
        sys.exit(1)
        
    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    if not token:
        print("GitHub Tokenia ei löydetty ympäristömuuttujista (GITHUB_TOKEN tai GH_TOKEN).")
        token = input("Syötä GitHub Personal Access Token (PAT): ").strip()
        if not token:
            print("Tokenia ei annettu. Keskeytetään.")
            sys.exit(1)
            
    print(f"Luetaan issuet tiedostosta {ISSUES_FILE}...")
    issues = parse_issues(ISSUES_FILE)
    print(f"Löydettiin {len(issues)} issue-kuvausta.")
    
    print(f"Luodaan issuet repositorioon {REPO}...")
    success_count = 0
    for issue in issues:
        if create_github_issue(token, REPO, issue["title"], issue["body"]):
            success_count += 1
            
    print(f"\nValmis! Luotiin {success_count}/{len(issues)} issuea.")

if __name__ == "__main__":
    main()
