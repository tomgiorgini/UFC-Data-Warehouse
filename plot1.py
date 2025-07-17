import os
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# Create output folder
output_dir = 'C:/Users/tomma/OneDrive/Desktop/ufc/Progetto-DM/query1'
os.makedirs(output_dir, exist_ok=True)

# Load data
df = pd.read_csv('query_1.csv')

# Filter out catch weight, 'Other' and Women's Featherweight
df = df[
    (~df['weightclass'].str.contains('Catch Weight', na=False)) &
    (df['finish_type'] != 'Other') &
    (df['weightclass'] != "Women's Featherweight")
]

# Define weightclass orders
men_order = [
    'Flyweight', 'Bantamweight', 'Featherweight', 'Lightweight',
    'Welterweight', 'Middleweight', 'Light Heavyweight', 'Heavyweight'
]
women_order = [
    "Women's Strawweight", "Women's Flyweight",
    "Women's Bantamweight"
]

df_men = df[df['weightclass'].isin(men_order)].copy()
df_women = df[df['weightclass'].isin(women_order)].copy()

# Metrics to plot
metrics = [
    'avg_avgkd', 'avg_avgsigstrlanded', 'avg_avgsigstratt',
    'avg_avgtdlanded', 'avg_avgtdatt', 'avg_avgctrltime',
    'avg_avgsubatt'
]

# Plotting with manual bar positions so line markers align on bars
for metric in metrics:
    for subset, order, prefix in [(df_men, men_order, 'men'), (df_women, women_order, 'women')]:
        pivot = subset.pivot(index='weightclass', columns='finish_type', values=metric).reindex(order)
        n_classes = len(order)
        finish_types = pivot.columns
        x = np.arange(n_classes)
        total_width = 0.8
        n_series = len(finish_types)
        bar_width = total_width / n_series
        
        fig, ax = plt.subplots(figsize=(8, 4) if prefix=='men' else (6, 4))
        # Plot bars
        for i, ft in enumerate(finish_types):
            ax.bar(x + i*bar_width, pivot[ft], width=bar_width, label=ft)
            # Plot line exactly on top of bars
            ax.plot(x + i*bar_width, pivot[ft], linewidth=2)
        
        ax.set_xticks(x + total_width/2 - bar_width/2)
        ax.set_xticklabels(order, rotation=45)
        ax.set_title(f'{prefix.capitalize()}: Average {metric} by Finish Type')
        ax.set_xlabel('Weightclass')
        ax.set_ylabel(metric)
        ax.legend(title='finish_type')
        plt.tight_layout()
        filename = f'{prefix}_{metric}.png'
        fig.savefig(os.path.join(output_dir, filename))
        plt.close(fig)

# List saved files
print("Saved plots:", os.listdir(output_dir))
