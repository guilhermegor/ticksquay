### PATHS FUNCTIONS ###

# pypi.org libs
import os
import sys


class PathFuncs:

    @property
    def root_py_dev(self) -> str:
        '''
        DOCSTRING:
        INPUTS:
        OUTPUTS:
        '''
        return sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '...')))

    @property
    def root_py_project(self) -> str:
        '''
        DOCSTRING:
        INPUTS:
        OUTPUTS:
        '''
        return sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))