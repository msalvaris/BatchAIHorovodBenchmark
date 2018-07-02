from bokeh.models import ColumnDataSource, FactorRange
from bokeh.plotting import figure
from bokeh.transform import factor_cmap
from bokeh.models import Legend, LegendItem
from bokeh.models import Label
from bokeh.io import export_svgs, export_png
import pandas as pd
import json


palette = ["#717cbb", "#89b9df", "#8a4b9a"]

def read_json(filename):
    with open(filename) as f:
        return json.load(f)



def main(filename='results.json'):
    results_single_node=read_json(filename)
    df = pd.DataFrame(results_single_node)
    print(df)
    results = (df[df['MPI'].isin(['open', 'intel'])][['GPUs', 'MPI', 'Images/Second']].sort_values(by=['GPUs', 'MPI'])
               .assign(GPUs=df.GPUs.astype(str))
               .replace({'MPI': {'intel': 'IntelMPI',
                                 'open': 'OpenMPI+NCCL',
                                 'local': 'SingleGPU'}})
               .set_index(['GPUs', 'MPI'], drop=False))

    res_dict = results['Images/Second'].to_dict()
    factors = list(res_dict.keys())
    source = ColumnDataSource(data=dict(x=factors, counts=list(res_dict.values()), MPI=results['MPI']))
    p = figure(x_range=FactorRange(*factors), plot_height=400, plot_width=800,
               toolbar_location=None, tools="", title="Training throughput for ResNet50 with synthetic data (V100)")

    p.vbar(x='x', top='counts', width=0.9, source=source, line_color="white", legend='MPI',
                fill_color=factor_cmap('x', palette=palette, factors=['IntelMPI', 'OpenMPI+NCCL'], start=1, end=4))

    p.y_range.start = 0
    p.x_range.range_padding = 0.3
    p.xaxis.major_label_orientation = 1.2
    p.xgrid.grid_line_color = None
    p.yaxis.axis_label = 'Images/Second'
    vb2 = p.vbar(x=[-2], top=[350], width=0.9, line_color="white", fill_color=palette[-1])
    a = p.renderers[4]
    a.visible = False
    legend = Legend(items=[
        a.items[0],
        LegendItem(label="Single GPU", renderers=[vb2])
    ], location=(0, -10))
    p.add_layout(legend, 'right')
    citation = Label(x=-4.8, y=-1100,
                     text='Single GPU', render_mode='css',
                     border_line_color=None,
                     background_fill_color=None, angle=1.2, text_font_size='12pt',
                     text_color=palette[-1])

    p.add_layout(citation)

    p.output_backend = "svg"
    export_svgs(p, filename="plot.svg")


if __name__=="__main__":
    main()