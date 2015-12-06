#!/bin/sh
./tex2img --workingdir current --no-merge-output-files --transparent --with-text --delete-display-size sample.tex ./1/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --background-color CCFFCC --with-text --delete-display-size sample.tex ./2/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --margins 10 --unit bp --transparent --with-text --delete-display-size sample.tex ./3/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --margins 10 --unit bp --background-color CCFFCC --with-text --delete-display-size sample.tex ./4/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --transparent --with-text --delete-display-size sample.tex ./5/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --background-color CCFFCC --with-text --delete-display-size sample.tex ./6/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --margins 10 --unit bp --transparent --with-text --delete-display-size sample.tex ./7/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --margins 10 --unit bp --background-color CCFFCC --with-text --delete-display-size sample.tex ./8/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --transparent --no-with-text  --delete-display-size sample.tex ./9/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --background-color CCFFCC --no-with-text  --delete-display-size sample.tex ./10/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --margins 10 --unit bp --transparent --no-with-text  --delete-display-size sample.tex ./11/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --margins 10 --unit bp --background-color CCFFCC --no-with-text  --delete-display-size sample.tex ./12/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --transparent --no-with-text  --delete-display-size sample.tex ./13/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --background-color CCFFCC --no-with-text  --delete-display-size sample.tex ./14/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --margins 10 --unit bp --transparent --no-with-text  --delete-display-size sample.tex ./15/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --margins 10 --unit bp --background-color CCFFCC --no-with-text  --delete-display-size sample.tex ./16/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --transparent --with-text --delete-display-size sample.tex ./17/"sam ple".svg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --background-color CCFFCC --with-text --delete-display-size sample.tex ./18/"sam ple".svg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --margins 10 --unit bp --transparent --with-text --delete-display-size sample.tex ./19/"sam ple".svg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --margins 10 --unit bp --background-color CCFFCC --with-text --delete-display-size sample.tex ./20/"sam ple".svg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --transparent --no-with-text  --delete-display-size sample.tex ./21/"sam ple".svg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --background-color CCFFCC --no-with-text  --delete-display-size sample.tex ./22/"sam ple".svg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --margins 10 --unit bp --transparent --no-with-text  --delete-display-size sample.tex ./23/"sam ple".svg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --margins 10 --unit bp --background-color CCFFCC --no-with-text  --delete-display-size sample.tex ./24/"sam ple".svg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --animation-delay 0.5 --animation-loop 0 --transparent --delete-display-size sample.tex ./25/"sam ple".svg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --animation-delay 0.5 --animation-loop 0 --background-color CCFFCC --delete-display-size sample.tex ./26/"sam ple".svg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --animation-delay 0.5 --animation-loop 0 --margins 10 --unit bp --transparent --delete-display-size sample.tex ./27/"sam ple".svg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --animation-delay 0.5 --animation-loop 0 --margins 10 --unit bp --background-color CCFFCC --delete-display-size sample.tex ./28/"sam ple".svg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --transparent --no-plain-text sample.tex ./29/"sam ple".eps; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --background-color CCFFCC --no-plain-text sample.tex ./30/"sam ple".eps; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --margins 10 --unit bp --transparent --no-plain-text sample.tex ./31/"sam ple".eps; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --margins 10 --unit bp --background-color CCFFCC --no-plain-text sample.tex ./32/"sam ple".eps; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --transparent --plain-text sample.tex ./33/"sam ple".eps; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --background-color CCFFCC --plain-text sample.tex ./34/"sam ple".eps; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --margins 10 --unit bp --transparent --plain-text sample.tex ./35/"sam ple".eps; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --margins 10 --unit bp --background-color CCFFCC --plain-text sample.tex ./36/"sam ple".eps; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --transparent sample.tex ./37/"sam ple".emf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --background-color CCFFCC sample.tex ./38/"sam ple".emf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --margins 10 --unit bp --transparent sample.tex ./39/"sam ple".emf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --margins 10 --unit bp --background-color CCFFCC sample.tex ./40/"sam ple".emf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --transparent sample.tex ./41/"sam ple".png; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --background-color CCFFCC sample.tex ./42/"sam ple".png; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --margins 10 --unit bp --transparent sample.tex ./43/"sam ple".png; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --margins 10 --unit bp --background-color CCFFCC sample.tex ./44/"sam ple".png; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current sample.tex ./45/"sam ple".jpg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --background-color CCFFCC sample.tex ./46/"sam ple".jpg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --margins 10 --unit bp sample.tex ./47/"sam ple".jpg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --margins 10 --unit bp --background-color CCFFCC sample.tex ./48/"sam ple".jpg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current sample.tex ./49/"sam ple".bmp; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --background-color CCFFCC sample.tex ./50/"sam ple".bmp; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --margins 10 --unit bp sample.tex ./51/"sam ple".bmp; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --margins 10 --unit bp --background-color CCFFCC sample.tex ./52/"sam ple".bmp; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --transparent --no-quick sample.tex ./53/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --background-color CCFFCC --no-quick sample.tex ./54/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --margins 10 --unit bp --transparent --no-quick sample.tex ./55/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --margins 10 --unit bp --background-color CCFFCC --no-quick sample.tex ./56/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --transparent --no-quick sample.tex ./57/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --background-color CCFFCC --no-quick sample.tex ./58/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --margins 10 --unit bp --transparent --no-quick sample.tex ./59/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --margins 10 --unit bp --background-color CCFFCC --no-quick sample.tex ./60/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --transparent --no-quick sample.tex ./61/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --background-color CCFFCC --no-quick sample.tex ./62/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --margins 10 --unit bp --transparent --no-quick sample.tex ./63/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --margins 10 --unit bp --background-color CCFFCC --no-quick sample.tex ./64/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --animation-delay 0.5 --animation-loop 0 --transparent --no-quick sample.tex ./65/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --animation-delay 0.5 --animation-loop 0 --background-color CCFFCC --no-quick sample.tex ./66/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --animation-delay 0.5 --animation-loop 0 --margins 10 --unit bp --transparent --no-quick sample.tex ./67/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --animation-delay 0.5 --animation-loop 0 --margins 10 --unit bp --background-color CCFFCC --no-quick sample.tex ./68/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --transparent --quick sample.tex ./69/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --background-color CCFFCC --quick sample.tex ./70/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --margins 10 --unit bp --transparent --quick sample.tex ./71/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --margins 10 --unit bp --background-color CCFFCC --quick sample.tex ./72/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --transparent --quick sample.tex ./73/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --background-color CCFFCC --quick sample.tex ./74/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --margins 10 --unit bp --transparent --quick sample.tex ./75/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --margins 10 --unit bp --background-color CCFFCC --quick sample.tex ./76/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --transparent --quick sample.tex ./77/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --background-color CCFFCC --quick sample.tex ./78/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --margins 10 --unit bp --transparent --quick sample.tex ./79/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --margins 10 --unit bp --background-color CCFFCC --quick sample.tex ./80/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --animation-delay 0.5 --animation-loop 0 --transparent --quick sample.tex ./81/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --animation-delay 0.5 --animation-loop 0 --background-color CCFFCC --quick sample.tex ./82/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --animation-delay 0.5 --animation-loop 0 --margins 10 --unit bp --transparent --quick sample.tex ./83/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --animation-delay 0.5 --animation-loop 0 --margins 10 --unit bp --background-color CCFFCC --quick sample.tex ./84/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
