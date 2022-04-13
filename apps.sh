!/bin/bash

# Machine Setup Script by Federated Computer, Inc.

echo -e '# ## ## ## ## ## ## ## ## ## ## ## ## #'
echo -e '#        Laying Down the Apps         #'
echo -e '# ## ## ## ## ## ## ## ## ## ## ## ## #'

echo -e

date

# override locale to eliminate parsing errors (i.e. using commas a delimiters rather than periods)
export LC_ALL=C