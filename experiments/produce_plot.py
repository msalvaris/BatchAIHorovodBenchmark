import json
import pandas as pd
from bokeh.io import export_svgs
from bokeh.models import ColumnDataSource, FactorRange
from bokeh.models import Legend
from bokeh.plotting import figure
from bokeh.transform import factor_cmap

_PALETTE = ["#717cbb", "#89b9df", "#8a4b9a"]


def read_json(filename):
    with open(filename) as f:
        return json.load(f)

def to_columnsource_and_factors(df):
    results = (df[df['MPI'].isin(['open', 'intel'])][['GPUs', 'MPI', 'Images/Second']].sort_values(by=['GPUs', 'MPI'])
               .assign(GPUs=df.GPUs.astype(str))
               .replace({'MPI': {'intel': 'IntelMPI',
                                 'open': 'OpenMPI+NCCL',
                                 'local': 'SingleGPU'}})
               .set_index(['GPUs', 'MPI'], drop=False))

    res_dict = results['Images/Second'].to_dict()
    factors = list(res_dict.keys())
    counts = list(res_dict.values())
    MPI = results['MPI'].tolist()
    factors.insert(0, ('1', 'Single GPU'))
    counts.insert(0, df[df['MPI'] == 'local']['Images/Second'].iloc[0])
    MPI.insert(0, 'Single GPU')
    source = ColumnDataSource(data=dict(x=factors, counts=counts, MPI=MPI))
    return source, factors

def _add_legend(p):
    old_legend = p.renderers[4] # Select legend
    old_legend.visible = False # Make the old legend invisible

    # In order to set the legend outside the image we need to create a new one
    new_legend = Legend(items=[
        old_legend.items[0]
    ], location=(0, 400))
    new_legend.label_text_font_size = '20px'
    p.add_layout(new_legend, 'right')
    return p

def main(filename='results.json'):
    results_single_node=read_json(filename)
    df = pd.DataFrame(results_single_node)

    print(df)

    source, factors = to_columnsource_and_factors(df)

    p = figure(x_range=FactorRange(*factors), plot_height=800, plot_width=1600, output_backend="svg",
               toolbar_location=None, tools="", title="Training throughput for ResNet50 with synthetic data (V100)".format(df['GPU Type'].iat[0]))
    p.vbar(x='x', top='counts', width=0.9, source=source, line_color="white", legend='MPI',
           fill_color=factor_cmap('x', palette=_PALETTE, factors=['IntelMPI', 'OpenMPI+NCCL', 'Single GPU'], start=1, end=3))

    p.y_range.start = 0
    p.x_range.range_padding = 0.1
    p.xaxis.major_label_orientation = 1.3
    p.xaxis.group_text_font_size='20px'
    p.xaxis.major_label_text_font_size='15px'
    p.xgrid.grid_line_color = None
    p.yaxis.axis_label_text_font_size='20px'
    p.yaxis.major_label_text_font_size='20px'
    p.yaxis.axis_label = 'Images/Second'
    p.xaxis.axis_label = 'Number of GPUs'
    p.xaxis.axis_label_text_font_size='20px'
    p = _add_legend(p)
    export_svgs(p, filename="plot.svg")





if __name__=="__main__":
    main()
