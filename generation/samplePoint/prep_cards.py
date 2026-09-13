import argparse
import re
import math
import os
import shutil

def main():
    parser = argparse.ArgumentParser(description="Scale WCs and package gridpack cards.")
    parser.add_argument("--log", required=True, help="Raw MadGraph output log")
    parser.add_argument("--cards-dir", required=True, help="Directory containing the base cards")
    parser.add_argument("--proc-card", required=True, help="Path to base proc_card.dat")
    parser.add_argument("--name", required=True, help="Name of the gridpack/folder")
    parser.add_argument("--out-dir", default="../../", help="Target output directory for the folder")
    args = parser.parse_args()

    # 1. Create target directory
    target_dir = os.path.join(args.out_dir, args.name)
    os.makedirs(target_dir, exist_ok=True)

    results = []
    current_proc = ""
    err = False

    # 2. Parse raw log
    with open(args.log, 'r') as f:
        for line in f:
            if line.startswith('generate '):
                current_proc = line.strip()
                err = False
            elif 'interrupted with error' in line:
                err = True
            elif 'Cross-section :' in line and current_proc and not err:
                match = re.search(r"([-+]?\d*\.?\d+e[-+]?\d+|[-+]?\d*\.?\d+)", line.split(":")[1])
                if match:
                    results.append({'proc': current_proc, 'xsec': float(match.group(1))})
                    current_proc = ""

    if not results:
        print("Error: No valid cross sections found in the log.")
        return

    sm_value = results[0]['xsec']
    num_eft = len(results) - 1
    wc_scales = {}

    # 3. Calculate scaling factors
    for r in results[1:]:
        matches = re.findall(r'NP([a-zA-Z0-9]+)\^2==2', r['proc'])
        wc = next((m for m in matches if m != 'cpv'), None)

        if wc:
            try:
                wc_scales[wc] = math.sqrt(sm_value / (r['xsec'] * num_eft))
            except ZeroDivisionError:
                wc_scales[wc] = 0.0

    # 4. Write the modified param_card directly to the bundle directory
    base_param = os.path.join(args.cards_dir, "param_card.dat")
    out_param = os.path.join(target_dir, f"{args.name}_param_card.dat")

    with open(base_param, 'r') as f_in, open(out_param, 'w') as f_out:
        active_block = False
        for line in f_in:
            lower_line = line.strip().lower()
            if lower_line in ["block smeft", "block smeftcpv"]:
                active_block = True
            elif lower_line.startswith("block "):
                active_block = False

            if active_block and '#' in line:
                val_part, comment = line.split('#', 1)

                # SAFEGUARD: Ensure there is actually content before the '#'
                val_elements = val_part.split()
                if val_elements:
                    wc_match = re.search(r'([a-zA-Z0-9]+?)(?:Re|Im)?$', comment.strip())

                    if wc_match:
                        wc_name = wc_match.group(1)
                        idx = val_elements[0]

                        if wc_name in wc_scales:
                            new_val = f"{wc_scales[wc_name]:.6e}"
                            line = f" {idx:>3}  {new_val} # {comment}"
                        elif "1.00" in val_part:
                            line = f" {idx:>3}  {0.0:.6e} # {comment}"

            f_out.write(line)

    # 5. Extract physics processes from the original proc_card
    primary_proc = ""
    add_procs = []

    if os.path.exists(args.proc_card):
        with open(args.proc_card, 'r') as f_in:
            for line in f_in:
                if line.startswith('generate ') and not primary_proc:
                    primary_proc = line.split('NPprop=')[0].replace('generate ', '').strip()
                elif line.startswith('add process '):
                    add_procs.append(line.split('NPprop=')[0].replace('add process ', '').strip())
                elif line.startswith('output '):
                    break

    # 6. Write the simplified gridpack proc_card
    out_proc = os.path.join(target_dir, f"{args.name}_proc_card.dat")
    with open(out_proc, 'w') as f_out:
        f_out.write("import model SMEFTsim_topU3l_MwScheme_UFO\n\n")
        f_out.write("define p = g u c d s b u~ c~ d~ s~ b~\n")
        f_out.write("define j = p\n")
        f_out.write("define l+ = e+ mu+ ta+\n")
        f_out.write("define l- = e- mu- ta-\n")
        f_out.write("define vl = ve vm vt\n")
        f_out.write("define vl~ = ve~ vm~ vt~\n")
        f_out.write("define had = u c d s u~ c~ d~ s~\n\n")

        f_out.write(f"generate    {primary_proc}         NPprop=0 SMHLOOP=0 NP=1\n")
        for ap in add_procs:
            f_out.write(f"add process {ap}         NPprop=0 SMHLOOP=0 NP=1\n")

        f_out.write(f"\noutput {args.name} -nojpeg\n")

    # 7. Copy and prefix the remaining cards
    def bundle_card(src_name, target_name):
        src_path = os.path.join(args.cards_dir, src_name)
        if os.path.exists(src_path):
            dest_path = os.path.join(target_dir, target_name)
            shutil.copy(src_path, dest_path)

    bundle_card("run_card.dat", f"{args.name}_run_card.dat")
    bundle_card("reweight_card.dat", f"{args.name}_reweight_card.dat")
    bundle_card("extramodels.dat", f"{args.name}_extramodels.dat")
    bundle_card("fix_model.patch", f"{args.name}_fix_model.patch")

    print(f"Success! Cards bundle created at: {os.path.abspath(target_dir)}/")

if __name__ == "__main__":
    main()
