#!/usr/bin/env python3

import os
import re
import pandas as pd
import xlsxwriter
import argparse
from pathlib import Path
from pydrive2.auth import GoogleAuth
from pydrive2.drive import GoogleDrive

def parseoption():
    parser = argparse.ArgumentParser()
    parser.add_argument('-d', required=True, metavar='filepath', help="e.g. /home/tkosuge/fcsgxmss/NSUB003390")
    args = parser.parse_args()
    return args
def read_reports(data_dir: Path):
    outputname = data_dir.name
    report_files = sorted(data_dir.glob("*.fcs_gx_report.txt"))

    fcs_report = pd.DataFrame() # 結合用の空の DataFrame を作成
    for path in report_files:
        print(f"Opening: {path}")
        df = pd.read_csv(path, sep='\t', skiprows=2, header=None, engine='python', names=['seq_id', 'start_pos', 'end_pos', 'seq_len', 'action', 'div', 'agg_cont_cov', 'top_tax_name'])
        newdf = df.head(n=10)
        # print(newdf.loc[:,['seq_id', 'action', 'seq_len']].to_string(index=False))
        pattern = re.compile(r"\.\d+\.fcs_gx_report\.txt$")
        df['file_name'] = pattern.sub("", path.name)
        fcs_report =pd.concat([fcs_report, df], ignore_index=True)

    with pd.ExcelWriter(data_dir / f"{outputname}.xlsx", engine="xlsxwriter") as writer:
        fcs_report.loc[: ,['file_name', 'seq_id', 'start_pos', 'end_pos', 'seq_len', 'action', 'div', 'agg_cont_cov', 'top_tax_name']].to_excel(writer, sheet_name="FCS-GX", index=False)
        ws = writer.sheets["FCS-GX"]
        wb = writer.book
        # Font
        arial_fmt = wb.add_format({"font_name": "Arial"})
        # 先頭行固定
        ws.freeze_panes(1, 0)
        # 列幅調整
        column_widths = [32, 16, 12 , 12, 12, 12, 24, 12, 32]
        for i, col in enumerate(fcs_report.columns):
            # max_len = fcs_report[col].astype(str).map(len).max()
            # header_len = len(col)
            # width = max(max_len, header_len) + 2
            width = column_widths[i] # 列幅はあらかじめ設定したものに変更
            ws.set_column(i, i, width, arial_fmt)
    global contami_count
    contami_count = len(fcs_report['seq_id'])
    print(f'{contami_count} contamination')

def upload_gdrive(file_path: Path, fid):
    gauth = GoogleAuth(settings_file='/home/w3const/fcsgx_mss/settings.yaml')
    gauth.LocalWebserverAuth()
    drive = GoogleDrive(gauth)
    # インスタンスを作成
    file = drive.CreateFile({'parents': [{'id': fid}]})
    # アップロードしたいファイルを指定
    file.SetContentFile(file_path)
    # そのままだとGdriveでは、ローカルでのファイルパス自体がファイル名になってしまうので、ファイル名を指定しておく
    file['title'] = os.path.basename(file_path)
    # アップロード
    file.Upload()

def main():
    opt = parseoption()
    # DATA_DIR = Path("/home/tkosuge/0209/NSUB003390")
    # filepath オブジェクトに変換
    DATA_DIR = Path(opt.d)
    read_reports(DATA_DIR)
    XLS_FILEPATH = DATA_DIR / f"{DATA_DIR.name}.xlsx"
    if Path(XLS_FILEPATH).exists():
        print(f"{XLS_FILEPATH} is created successfully.")
        if contami_count > 0:
            upload_gdrive(XLS_FILEPATH, '15E0yNLuRQdmW5bN6wDOxEoAzE-EuLyjH')
            print(f"{XLS_FILEPATH} is uploaded to Gdrive.")

if __name__ == "__main__":
    main()
