# Foundational Learning Gradient

This repository reproduces the analysis behind UNICEF’s scrollytelling story, [The learning divide: Which children are gaining foundational skills?](https://public.flourish.studio/story/3436779/). It generates the standardized tables and exported figures to recreate the published charts.

The analysis is based on the Foundational Learning Skills (FLS) module from the sixth round of the [Multiple Indicator Cluster Surveys (MICS)](https://mics.unicef.org/surveys). Inputs are retrieved from the [UNICEF Indicator Global Data Warehouse](https://sdmx.data.unicef.org/webservice/data.html) and transformed into cross-country comparable outputs.

Early learning sets the foundation for everything that follows in school, but in many education systems children spend several years enrolled before they gain foundational skills. Understanding when learning starts to accelerate, and which children are being left behind, helps clarify what is driving low learning outcomes and persistent inequality. The Learning Gradient tracks the share of children demonstrating foundational skills across grades to help answer these questions.

The analysis highlights two patterns recurring across countries. First, learning often happens too late: most Grade 3 children still lack foundational reading, and in MICS6 Africa countries only 13% meet the benchmark at that stage. In many contexts, major gains appear only toward the end of primary school or into lower secondary, pointing to delayed learning as a central challenge rather than the impossibility of learning. Second, wealth gaps persist at every stage: children from poorer households are consistently less likely to reach foundational reading than those from richer households. In MICS6 Africa countries, the poorest children often complete primary school with foundational reading levels comparable to where the richest children in other regions begin.

Two companion interactive dashboards are published online: [Foundational skills across countries](https://unicef-dapm.shinyapps.io/learning-gradient-visual1/) and [Gaps in foundational skills](https://unicef-dapm.shinyapps.io/learning-gradient-visual2/). They mirror the story's analytical views and allow users to explore patterns by adjusting filters and comparison groups in an interactive interface. This repository's primary outputs are static tables and exported chart images; the dashboards are provided as a complementary way to explore the same concepts.

## Technical overview

This repository rebuilds Learning Gradient analysis outputs starting from harmonized aggregates derived from MICS and stored in the UNICEF Global Data Warehouse. The pipeline retrieves Learning Gradient indicator data using the Data Warehouse API and transforms it into a consistent analytical structure suitable for cross-country comparison and visualization. The pipeline produces standardized output tables and exported PNG charts reflecting the scrollytelling visuals.

Further details on the Data Warehouse indicator structure, data flow, and pipeline sequence are available in the technical documentation: [Technical Note](00_documentation/0001_technical_note/Technical_Note.md)

---

## Reproducibility

This repository is designed to be reproducible end to end from the UNICEF Global Data Warehouse. For details on how to rerun the workflow and recreate published outputs, see the [Reproducibility Note](00_documentation/0002_reproducibility/Reproducibility_Note.md)

---

## Quick Navigation

- **Technical overview**: [Technical Note](00_documentation/0001_technical_note/Technical_Note.md)
- **Reproducibility**: [Reproducibility Note](00_documentation/0002_reproducibility/Reproducibility_Note.md)
- **API structure and codes**: [UNICEF DW API Data Description](00_documentation/0003_data_reference/000301_UNICEF_DW_API_Data_Description.md)
- **Output schema**: [Output Data Structure](00_documentation/0003_data_reference/000302_Output_Data_Structure.md)

---

## Contact

This repository is maintained by the UNICEF Global Education team within the Data and Analytics section. The team works to transform MICS data into evidence for education policy insights and advocacy.

For questions related to the repository or the Learning Gradient analysis, please contact:
[smishra@unicef.org](mailto:smishra@unicef.org), [ainoman@unicef.org](mailto:ainoman@unicef.org)
