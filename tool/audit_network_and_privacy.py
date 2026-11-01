import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

def find_http_urls():
    http_urls = []
    for folder in ["lib", "assets/data"]:
        for root, dirs, files in os.walk(folder):
            for f in files:
                if f.endswith(".dart") or f.endswith(".json"):
                    p = os.path.join(root, f).replace("\\", "/")
                    with open(p, "r", encoding="utf-8", errors="ignore") as fp:
                        txt = fp.read()
                        matches = re.findall(r'http://[^\s"\'\)]+', txt)
                        for m in matches:
                            http_urls.append((p, m))
    return http_urls

def audit_location_and_geocoding():
    geocoding_refs = []
    location_refs = []
    for root, dirs, files in os.walk("lib"):
        for f in files:
            if f.endswith(".dart"):
                p = os.path.join(root, f).replace("\\", "/")
                with open(p, "r", encoding="utf-8", errors="ignore") as fp:
                    txt = fp.read()
                    if "geocoding" in txt or "Nominatim" in txt or "bigdatacloud" in txt.lower():
                        geocoding_refs.append(p)
                    if "Geolocator" in txt or "getCurrentPosition" in txt:
                        location_refs.append(p)
    return location_refs, geocoding_refs

def find_domains():
    https_urls = set()
    for folder in ["lib", "assets/data"]:
        for root, dirs, files in os.walk(folder):
            for f in files:
                if f.endswith(".dart") or f.endswith(".json"):
                    p = os.path.join(root, f)
                    with open(p, "r", encoding="utf-8", errors="ignore") as fp:
                        txt = fp.read()
                        matches = re.findall(r'https://[^\s"\'\)]+', txt)
                        for m in matches:
                            https_urls.add(m)

    domains = set()
    for u in https_urls:
        m = re.match(r'https://([^/:]+)', u)
        if m:
            domains.add(m.group(1))
    return sorted(domains)

def main():
    print("==================================================")
    print("NETWORK BOUNDARY & PRIVACY AUDIT")
    print("==================================================")

    # 1. HTTP URLs
    print("\n[1] Auditing cleartext HTTP URLs across lib/ and assets/data/...")
    http_urls = find_http_urls()
    print(f"Total cleartext http:// references: {len(http_urls)}")
    for p, u in http_urls[:30]:
        print(f"  {p}: {u}")

    # 2. Location & Geocoding paths
    print("\n[2] Auditing location & geocoding services...")
    loc_files, geo_files = audit_location_and_geocoding()
    print(f"Location services files: {len(loc_files)}")
    for f in loc_files:
        print(f"  {f}")
    print(f"Geocoding services files: {len(geo_files)}")
    for f in geo_files:
        print(f"  {f}")

    # 3. Domains
    print("\n[3] Auditing remote domains accessed by the app...")
    domains = find_domains()
    print(f"Total domains: {len(domains)}")
    for d in domains:
        print(f"  {d}")

if __name__ == "__main__":
    main()
