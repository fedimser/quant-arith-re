import json
import pandas as pd
import os
import time
import numpy as np
from matplotlib import pyplot as plt
import re
import math

METRICS = ["Logical qubits", "Physical qubits",
           "Logical depth", "Runtime (seconds)"]
METRICS_TO_PLOT = [1, 3]
DEFAULT_N_RANGE = [3] + [int(round(2**(0.25*i))) for i in range(8, 81)]
DEBUG = False


def _log2(x):
    return int(round(math.log2(x)))


def run_re_with_caching(estimate_func, op, n) -> list:
    """Runs resource estimation and stores result in CSV file."""
    file_name = f'results/{estimate_func.__name__}.csv'
    if not os.path.exists(file_name):
        df = pd.DataFrame(columns=['op', 'n'] + METRICS)
        df.to_csv(file_name, index=False)
    df = pd.read_csv(file_name)
    existing = df.loc[(df['op'] == op) & (df['n'] == n)]
    if len(existing) >= 1:
        return list(existing.iloc[0, 2:6])
    else:
        t0 = time.time()
        estimates = json.loads(estimate_func(op, n))
        if DEBUG:
            dt = time.time()-t0
            print(f"n={n}, op={op}, t={dt:.3f}s", flush=True)
        metrics = [
            estimates['physicalCounts']['breakdown']['algorithmicLogicalQubits'],
            estimates['physicalCounts']['physicalQubits'],
            estimates['physicalCounts']['breakdown']['logicalDepth'],
            estimates['physicalCounts']['runtime']/10**9,
        ]
        df.loc[len(df)] = [op, n] + metrics
        df.sort_values(by=["op", "n"], inplace=True)
        df.to_csv(file_name, index=False)
        return metrics


def run_re_experiments(ops_and_max_n, estimate_func, title=None):
    title = title or estimate_func.__name__
    ops = [op for op, _, _ in ops_and_max_n]
    n_ranges = {}
    aliases = {}
    for op, alias, max_n in ops_and_max_n:
        aliases[op] = alias
        n_ranges[op] = [n for n in DEFAULT_N_RANGE if n <= max_n]
    charts = [{op: [] for op in ops} for _ in range(len(METRICS_TO_PLOT))]
    plt.rcParams["font.family"] = "serif"

    # Run experiments.
    for n in DEFAULT_N_RANGE:
        for op in ops:
            if n not in n_ranges[op]:
                continue
            estimates = run_re_with_caching(estimate_func, op, n)
            for i in range(len(METRICS_TO_PLOT)):
                charts[i][op].append(estimates[METRICS_TO_PLOT[i]])

    min_n = min(DEFAULT_N_RANGE)
    max_n = max(n for _, _, n in ops_and_max_n)

    # Show charts.
    fig, ax = plt.subplots(figsize=(7, 6.5), nrows=len(METRICS_TO_PLOT),
                           ncols=1, sharex=True)
    fig.subplots_adjust(hspace=0)
    for i in range(len(METRICS_TO_PLOT)):
        for op in n_ranges.keys():
            ax[i].plot(n_ranges[op], charts[i][op],
                       label=aliases[op])
        ax[i].set_xlim([min_n, max_n])
        # ax[i].set_xlabel('Input size')
        ax[i].set_ylabel(METRICS[METRICS_TO_PLOT[i]])
        ax[i].set_xscale('log')
        ax[i].set_yscale('log')
        ax[i].grid(linestyle='--', alpha=0.5)
    ax[0].legend()

    # Custom title,
    ax[0].text(.5, .9, title,
               horizontalalignment='center', fontsize='x-large',
               transform=ax[0].transAxes)
    # Custom shared xlabel, just above the x lane.
    ax[-1].text(.5, .04, 'Input size (n)',
                horizontalalignment='center',
                transform=ax[1].transAxes)

    # Custom binary ticks.
    ax[-1].xaxis.set_ticks([2**i for i in range(2, 100) if 2**i <= max_n])
    ax[-1].xaxis.set_major_formatter(lambda x, pos: "$2^{%d}$" % _log2(x))
    ax[-1].minorticks_off()

    fig_name = re.sub(r'\W+', ' ', title.lower()).strip().replace(' ', '_')
    fig_name = f'img/{fig_name}.png'
    fig.savefig(fig_name, format='png',
                dpi=300, bbox_inches='tight')
    print(f'Charts saved to {fig_name}')
    plt.close()  # Prevent it from putputting to Jupyter.


def show_re_table(ops_and_max_n, estimate_func, n):
    print(f"n={n}")
    table = []
    for op, alias, max_n in ops_and_max_n:
        if n > max_n:
            continue
        estimates = run_re_with_caching(estimate_func, op, n)
        table.append([alias] + estimates)
    df = pd.DataFrame(table, columns=["Algorithm"] + METRICS)
    return df.style.highlight_min(color='lightgreen', subset=METRICS)


def trendline_analysis(ops_and_max_n, estimate_func, min_n=100):
    table = []
    for op, alias, max_n in ops_and_max_n:
        n_range = [n for n in DEFAULT_N_RANGE if n >= min_n and n <= max_n]
        X = [[1, np.log(n)] for n in n_range]
        metrics = np.array([run_re_with_caching(
            estimate_func, op, n) for n in n_range])
        trendlines = []
        for i in range(len(METRICS)):
            # Fit the line log(metric)=A+B*log(n).
            (A, B), _, _, _ = np.linalg.lstsq(
                X, np.log(metrics[:, i]), rcond=None)
            trendlines.append("%.04e * n^%.04f" % (np.exp(A), B))
        table.append([alias] + trendlines)
    df = pd.DataFrame(table, columns=["Algorithm"] + METRICS)
    return df
