### PATHS FUNCTIONS ###

# consultando módulos da python org
import os
from pathlib import Path
from typing import List, Union


class PathFuncs:

    def split_dir_name(self, dir_path:Union[str, Path]) -> List[str]:
        '''
        DOCSTRING:
        INPUTS:
        OUTPUTS:
        '''
        # cria um objeto Path
        path = Path(dir_path)
        # retorna os componentes do caminho como uma lista
        return [str(part) for part in path.parts]

    @property
    def root_py_dev(self) -> str:
        '''
        DOCSTRING:
        INPUTS:
        OUTPUTS:
        '''
        list_split_dir_name = self.split_dir_name(os.path.dirname(os.path.realpath(__file__)))
        return '\\'.join(list_split_dir_name[:-3])

    @property
    def root_py_project(self) -> str:
        '''
        DOCSTRING:
        INPUTS:
        OUTPUTS:
        '''
        list_split_dir_name = self.split_dir_name(os.path.dirname(os.path.realpath(__file__)))
        return '\\'.join(list_split_dir_name[:-2])