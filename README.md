[🇪🇸 Español](README_ES.md) | **🇬🇧 English**

# Introduction
This repository contains materials for the Silicon Sampling workshop. To date, the workshop has been taught at
- Max Planck Institute for Demographic Research - Summer Data Science Incubator Program
- SICSS 2026 - Buenos Aires

# Folder structure
```
factor_data_silicon_tutorial/
├── LICENSE
├── README.md
├── README_ES.md
├── _config.yml
├── imgs/
│   └── LOGO-FactorData-Negro.png
├── input_data/
│   └── WVS_wave7_migracion_prompts.csv
├── output_data/
│   ├── gpt-4o_Q130_v2_WVS_silicon_empirico_results.csv
│   ├── gpt-4o_V1_WVS_silicon_empirico_results.csv
│   ├── gpt-oss_120B_Q130_v2_WVS_silicon_empirico_results.csv
│   ├── gpt-oss_120b_V1_WVS_silicon_empirico_results.csv
│   ├── gpt-oss_20B_Q130_v2_WVS_silicon_empirico_results.csv
│   └── gpt-oss_20b_V1_WVS_silicon_empirico_results.csv
└── src/
    ├── EN_tutorial_wvs_silicon_empirico.ipynb
    └── ES_tutorial_wvs_silicon_empirico.ipynb
```

- `src` contains the tutorial notebooks (English and Spanish versions)
- `input_data` contains raw data
- `output_data` contains output data (simulations)

# Google Colab version
You can open the tutorial notebooks directly in Google Colab:
- [Spanish notebook](https://drive.google.com/file/d/1qRC_q_Uvr7tfBVVV3N-Leu9MtYmwbXkB/view?usp=sharing)
- [English notebook](https://drive.google.com/file/d/1vzEvTgfsQWd_qJAqDqYysa5yl6O3FTvK/view?usp=sharing)

# Slides
- [View presentation](https://docs.google.com/presentation/d/1NYN-YYr1fLNvnJ9whPko7_ZYv6M9Wp5eVbb4zZ98Xj4/edit?usp=sharing)

# Data sources
The tutorial uses data from the 2017-2022 wave of the [World Values Survey](https://www.worldvaluessurvey.org/WVSDocumentationWV7.jsp)

That said, there are many other data sources that could be used. We mention just a few
- [Latinobarometro](https://www.latinobarometro.org/lat.jsp)
- [LAPOP](https://www.vanderbilt.edu/lapop/)

# Bibliography
Despite being a new field, there is a large body of literature on the subject. As expected, no consensus has been reached regarding the reliability and viability of these tools.
We present a (non-exhaustive) list of several relevant studies.

- Ahuja, K., Diddee, H., Hada, R., Ochieng, M., Ramesh, K., Jain, P., Nambi, A., Ganu, T., Segal, S., Axmed, M., Bali, K., & Sitaram, S. (2023). *MEGA: Multilingual evaluation of generative AI* [Preprint]. arXiv. https://arxiv.org/abs/2303.12528
- Amirova, A., Fteropoulli, T., Ahmed, N., Cowie, M. R., & Leibo, J. Z. (2024). Framework-based qualitative analysis of free responses of large language models: Algorithmic fidelity. *PLOS ONE, 19*(3), e0300024. https://doi.org/10.1371/journal.pone.0300024
- Argyle, L. P., Busby, E. C., Fulda, N., Gubler, J. R., Rytting, C., & Wingate, D. (2023). Out of one, many: Using language models to simulate human samples. *Political Analysis, 31*(3), 337–351. https://doi.org/10.1017/pan.2023.2
- Atari, M., Xue, M. J., Park, P. S., Blasi, D. E., & Henrich, J. (2023). *Which humans?* [Preprint]. PsyArXiv. https://doi.org/10.31234/osf.io/5b26t
- Bisbee, J., Clinton, J. D., Dorff, C., Kenkel, B., & Larson, J. M. (2024). Synthetic replacements for human survey data? The perils of large language models. *Political Analysis, 32*(4), 401–416. https://doi.org/10.1017/pan.2024.5
- Boelaert, J., Coavoux, S., Ollion, É., Petev, I., & Präg, P. (2024). *Machine bias: How do generative language models answer opinion polls?* [Preprint]. OSF Preprints. https://doi.org/10.31235/osf.io/r2pnb
- Chen, Q., Kaza, V. S., Zinn, A. K., Portmann, M., & Dolnicar, S. (2025). Can large language models substitute participant-based survey studies? *Advances in Methods and Practices in Psychological Science*. Advance online publication. https://doi.org/10.1177/25152459251354844
- Cheng, M., Durmus, E., & Jurafsky, D. (2023). Marked personas: Using natural language prompts to measure stereotypes in language models. In *Proceedings of the 61st Annual Meeting of the Association for Computational Linguistics (Volume 1: Long Papers)* (pp. 1504–1532). https://aclanthology.org/2023.acl-long.84.pdf
- Dominguez-Olmedo, R., Hardt, M., & Mendler-Dünner, C. (2024). Questioning the survey responses of large language models. In *Advances in Neural Information Processing Systems 37*. https://proceedings.neurips.cc/paper_files/paper/2024/file/515c62809e0a29729d7eec26e2916fc0-Paper-Conference.pdf
- Geng, M., He, S., & Trotta, R. (2024). *Are large language models chameleons?* [Preprint]. arXiv. https://arxiv.org/abs/2405.19323
- Kotek, H., Dockum, R., & Sun, D. Q. (2023). Gender bias and stereotypes in large language models. In *Proceedings of the 2023 ACM Conference on Collective Intelligence* (pp. 12–24). https://doi.org/10.1145/3582269.3615599
- Lin, Z. (2025). Six fallacies in substituting large language models for human participants. *Advances in Methods and Practices in Psychological Science, 8*(3), 1–19. https://doi.org/10.1177/25152459251357566
- Qu, Y., & Wang, J. (2024). Performance and biases of large language models in public opinion simulation. *Humanities and Social Sciences Communications, 11*(1), Article 1162. https://doi.org/10.1057/s41599-024-03609-x
- Santurkar, S., Durmus, E., Ladhak, F., Lee, C., Liang, P., & Hashimoto, T. (2023). Whose opinions do language models reflect? In *Proceedings of the 40th International Conference on Machine Learning* (pp. 29971–30004). https://arxiv.org/abs/2303.17548
- Sarstedt, M., Adler, S. J., Rau, L., & Schmitt, B. (2024). Using large language models to generate silicon samples in consumer and marketing research: Challenges, opportunities, and guidelines. *Psychology & Marketing, 41*(6), 1254–1270. https://doi.org/10.1002/mar.21982
- Sun, S., Lee, E., Nan, D., Zhao, X., Lee, W., Jansen, B. J., & Kim, J. H. (2024). *Random silicon sampling: Simulating human sub-population opinion using a large language model based on group-level demographic information* [Preprint]. arXiv. https://arxiv.org/abs/2402.18144
- Yan, T., Viberg, O., Baker, R. S., & Kizilcec, R. F. (2024). Cultural bias and cultural alignment of large language models. *PNAS Nexus, 3*(9), pgae346. https://doi.org/10.1093/pnasnexus/pgae346
