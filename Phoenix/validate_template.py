import glob
from subprocess import call


def main():
    """
    Iterate over all cloud formation templates running validate command against them
    """
    for file_path in glob.iglob('./*.json'):
        if "params" not in file_path:
            print('Validating file: {0}'.format(file_path))
            call(['aws', 'cloudformation', 'validate-template', '--template-body', 'file://{0}'.format(file_path)])
        else:
            print('Not validating parameters file: {0}'.format(file_path))


if __name__ == "__main__":
    main()
