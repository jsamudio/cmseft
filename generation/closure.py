#!/usr/bin/env python3

import argparse
import uproot
import hist
import awkward as ak
from coffea.nanoevents import NanoEventsFactory, NanoAODSchema
import numpy as np
import matplotlib.pyplot as plt
import mplhep as hep
import warnings

plt.style.use(hep.style.CMS)
NanoAODSchema.warn_missing_crossrefs = False


def decode_WCnames(wc_names_raw):
    WCnames_out = []
    WCname = ''
    for val in wc_names_raw:
        fourchar = int(val).to_bytes(4, 'big').decode()
        if '-' in fourchar:
            WCname += fourchar.split('-')[-1]
        else:
            if len(WCname):
                WCnames_out.append(WCname)
            WCname = fourchar.lstrip('\x00')
    WCnames_out.append(WCname)
    return ["SM"] + WCnames_out


def get_wc_weight(events, wc_names, name='sm', value=0.0):
    sm_weight = events.EFTfitCoefficients[:, 0]

    if name.lower() == 'sm':
        return sm_weight

    wc_idx = wc_names.index(name)
    index1 = events.EFTfitCoefficientIndex1[0]
    index2 = events.EFTfitCoefficientIndex2[0]

    matching1 = np.where((index1 == wc_idx) & (index2 == 0))[0]
    matching2 = np.where((index1 == wc_idx) & (index2 == wc_idx))[0]

    wc_lin = ak.flatten(events.EFTfitCoefficients[:, matching1] * value)
    wc_sq = ak.flatten(events.EFTfitCoefficients[:, matching2] * value**2)

    return sm_weight + wc_lin + wc_sq


if __name__ == '__main__':

    argParser = argparse.ArgumentParser(description="Argument parser")
    argParser.add_argument('--fixed', action='store',
                           default='root://eosuser.cern.ch//eos/user/j/jsamudio/madjaxTut/nanogen_ttbar_ctg1.root',
                           help="Fixed sample file")
    argParser.add_argument('--reweighted', action='store',
                           default='root://eosuser.cern.ch//eos/user/j/jsamudio/madjaxTut/nanogen_ttbar_madjax.root',
                           help="Reweighted sample file")
    argParser.add_argument('--output', action='store', default='./closure.pdf', help="Output file")
    argParser.add_argument('--wc-name', action='store', default='ctgre', help="Wilson Coefficient name (e.g. ctgre)")
    argParser.add_argument('--wc-value', action='store', type=float, default=1.0, help="Wilson Coefficient value")
    args = argParser.parse_args()

    events_fixed = NanoEventsFactory.from_root(
        args.fixed,
        schemaclass=NanoAODSchema,
    ).events()

    events_reweighted = NanoEventsFactory.from_root(
        args.reweighted,
        schemaclass=NanoAODSchema,
    ).events()

    # Extract dynamic MadJax weights
    wc_names = decode_WCnames(events_reweighted.WCnames[0])
    mj_weight = get_wc_weight(events_reweighted, wc_names, name=args.wc_name, value=args.wc_value)

    ht_axis = hist.axis.Regular(25, 100, 1500, name="ht", label="HT", underflow=True, overflow=True)

    h_reweighted = hist.Hist(
        ht_axis,
        storage=hist.storage.Weight(),
    )

    h_reweighted.fill(
        ht=ak.sum(events_reweighted.GenJet.pt, axis=1),
        weight=mj_weight,
    )

    h_fixed = hist.Hist(
        ht_axis,
        storage=hist.storage.Weight(),
    )

    # Kept exactly as in original non-MadJax script (unweighted fill relying on density=True later)
    h_fixed.fill(
        ht=ak.sum(events_fixed.GenJet.pt, axis=1),
    )

    fig, ax = plt.subplots()

    h_fixed.plot1d(
        ax=ax,
        label=f'{args.wc_name}={args.wc_value} (fixed)',
        density=True,
    )
    h_reweighted.plot1d(
        ax=ax,
        label=f'{args.wc_name}={args.wc_value} (reweighted)',
        density=True,
    )

    ax.set_ylabel(r'a.u.')
    ax.set_xlabel(r'\(H_{T} (GeV)\)')
    ax.set_yscale("log")

    plt.legend()

    fig.savefig(args.output)
    print(f"Figure saved in {args.output}")
