This project aimed to develop my SQL skills using MS SQL Server and coral data collected in Malaysia in 2019/2020 by Szereday et al., 2024 <a href="https://doi.org/10.1007/s00227-024-04495-2" >(click me), investigating the effects of back-to-back thermal stress events on coral health (i.e., bleaching response).

The dataset includes 3755 rows with following columns:
Year,
Wind,
Depth,
Habitat,
Site,
Genus,
Form,
Bleaching Score,
Bleaching_Binary,
Depth_Binary,
Wind_Binary,
max_DHW,
Depth (m),
Morphotaxa,
avg_DHW,
SS_DHW,
CRW_DHW.

Here I focused on the parameters interesting to me: Year, Depth (m), Site, (Genus, Form), Morphotaxa (concat(GenusForm)), Bleaching Score.
Year FLOAT,
Depth (m) FLOAT,
Site nvarchar(255),
Morphotaxa nvarchar(255),
Bleaching Score FLOAT.
The higher the Bleaching Score, the higher the loss of pigmentation, the lower the coral health is.

I divided the project into several pieces, each answering one scientific question while training basic-intermediate SQL skills.
