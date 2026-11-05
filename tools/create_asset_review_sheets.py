#!/usr/bin/env python3
"""Compose labeled evidence sheets from actual Godot asset captures."""
import argparse
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[1]


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--renders',type=Path,required=True);a=p.parse_args()
    dest=ROOT/'docs/previews/asset-batch-01';dest.mkdir(parents=True,exist_ok=True)
    def font(n):return ImageFont.truetype(str(ROOT/'assets/fonts/manrope.ttf'),n)
    canvas=Image.new('RGB',(1600,2640),'#101c31');draw=ImageDraw.Draw(canvas)
    draw.text((48,30),'LAMONT LABS  /  MYSTICRUN',font=font(20),fill='#d3ac68')
    draw.text((45,70),'Actual 3D asset batch 01',font=font(58),fill='#f0e9dd')
    draw.text((48,150),'57 GLB files  •  114 engine captures  •  Source licenses preserved',font=font(23),fill='#b6c9dc')
    def section(y,title,subtitle):
        draw.line((48,y,1552,y),fill='#34465b',width=2)
        draw.text((48,y+22),title,font=font(28),fill='#f0e9dd')
        draw.text((48,y+62),subtitle,font=font(18),fill='#adc1d3')
    def card(name,label,x,y,w,h,caption):
        im=Image.open(a.renders/(name+'-front.png')).convert('RGB').crop((0,120,960,895))
        im.thumbnail((w,h-74),Image.Resampling.LANCZOS);canvas.paste(im,(x+(w-im.width)//2,y))
        draw.text((x+12,y+h-65),label,font=font(20 if w>400 else 16),fill='#f0e9dd')
        draw.text((x+12,y+h-33),caption,font=font(16 if w>400 else 13),fill='#9db5c9')
    section(210,'Rigged costume sources','Quaternius free Standard edition  •  Heads are separate  •  1024px PBR maps')
    items=[('outfit_female_ranger','Female Ranger','Layered leather and quilted cloth'),('outfit_male_ranger','Male Ranger','Belts, buckles and shoulder armor'),('outfit_female_peasant','Female Peasant','Corset, sleeves and boots'),('outfit_male_peasant','Male Peasant','Tunic, folded cloth and leather')]
    for i,(n,label,caption) in enumerate(items):card(n,label,48+(i%2)*760,320+(i//2)*540,744,520,caption)
    section(1440,'Five original equipment and landmark models','Lamont Labs geometry  •  Actual GLB renders')
    for i,(n,label) in enumerate([('skyguard_sword','Skyguard sword'),('moonspire_staff','Moonspire staff'),('citadel_lantern','Citadel lantern'),('relic_waystone','Relic waystone'),('skybridge_gateway','Skybridge gateway')]):card(n,label,48+i*302,1550,292,365,'Original vertex paint and PBR')
    section(1950,'Environment selection','28 selected KayKit meshes  •  CC0  •  Six examples below')
    for i,(n,label) in enumerate([('kaykit_pillar_decorated','Carved pillar'),('kaykit_wall_arched','Masonry arch'),('kaykit_chest_gold','Treasure chest'),('kaykit_banner_shield_blue','Heraldic banner'),('kaykit_barrel_large_decorated','Detailed barrel'),('kaykit_torch_mounted','Mounted torch')]):card(n,label,48+i*252,2060,240,310,'Kay Lousberg / KayKit')
    draw.text((48,2450),'These are replacement candidates. The current APK has not changed.',font=font(24),fill='#e3c896')
    draw.text((48,2500),'Next benchmark: a fully assembled Knight, reviewed in motion and from the chase camera.',font=font(20),fill='#adc1d3')
    draw.text((48,2565),'GODOT 4.7.2  /  DESKTOP GL COMPATIBILITY  /  NOVEMBER 5 2026',font=font(16),fill='#7295b2')
    canvas.save(dest/'overview.jpg',quality=91,subsampling=0)
    catalog=json.loads((ROOT/'art/asset_batch_01/review/asset_catalog.json').read_text())
    for view in ['front','rear']:
        sheet=Image.new('RGB',(1800,2560),'#101c31');d=ImageDraw.Draw(sheet)
        d.text((35,28),'MYSTICRUN  /  COMPLETE '+view.upper()+' CATALOG',font=font(38),fill='#f0e9dd')
        d.text((35,83),'57 GLB files • 5 original props • 28 environment models • 4 outfits • 20 modular clothing parts',font=font(18),fill='#adc1d3')
        for i,item in enumerate(catalog['assets']):
            x=25+(i%6)*294;y=135+(i//6)*240
            im=Image.open(a.renders/(item['id']+'-'+view+'.png')).convert('RGB').crop((0,120,960,895));im.thumbnail((284,192),Image.Resampling.LANCZOS);sheet.paste(im,(x+(284-im.width)//2,y))
            label=item['label'];label=label if len(label)<=31 else label[:29]+'…'
            d.text((x+5,y+196),label,font=font(13),fill='#f0e9dd')
            d.text((x+5,y+216),str(item['triangles'])+' tris  /  '+item['license'],font=font(11),fill='#91abc2')
        sheet.save(dest/('catalog-'+view+'.jpg'),quality=87)
    print('Saved three actual-engine review sheets')


if __name__=='__main__':main()
