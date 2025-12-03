
import {
  HomePageToolkit,
  HomePageCompanyLogo,
  HomePageStarredEntities,
  TemplateBackstageLogo,
  HomePageRandomJoke,
} from '@backstage/plugin-home';
import { Content, Page } from '@backstage/core-components';
import { Grid, makeStyles } from '@material-ui/core';
import { SearchContextProvider } from '@backstage/plugin-search-react';
import { HomePageSearchBar } from '@backstage/plugin-search';

const useStyles = makeStyles(theme => ({
  searchBarInput: {
    maxWidth: '60vw',
    margin: 'auto',
    backgroundColor: theme.palette.background.paper,
    borderRadius: '50px',
    boxShadow: theme.shadows[1],
  },
  searchBarOutline: {
    borderStyle: 'none'
  },
  logo: {
      display: 'flex',
      justifyContent: 'center',
      marginTop: theme.spacing(8),
      marginBottom: theme.spacing(4),
  }
}));

export const HomePage = () => {
  const classes = useStyles();

  return (
    <SearchContextProvider>
      <Page themeId="home">
        <Content>
          <Grid container justifyContent="center" spacing={6}>
            <Grid item xs={12} className={classes.logo}>
                <HomePageCompanyLogo logo={<TemplateBackstageLogo classes={{ svg: '', path: '' }} />} />
            </Grid>
            <Grid item xs={12}>
              <HomePageSearchBar
                InputProps={{ classes: { root: classes.searchBarInput, notchedOutline: classes.searchBarOutline } }}
                placeholder="Search"
              />
            </Grid>
            <Grid item xs={12}>
              <Grid container justifyContent="center" spacing={6}>
                <Grid item xs={12} md={6}>
                  <HomePageStarredEntities />
                </Grid>
                <Grid item xs={12} md={6}>
                  <HomePageToolkit
                    tools={[
                      {
                        url: '/catalog',
                        label: 'Catalog',
                        icon: <TemplateBackstageLogo classes={{ svg: '', path: '' }} />,
                      },
                      {
                        url: '/docs',
                        label: 'Docs',
                        icon: <TemplateBackstageLogo classes={{ svg: '', path: '' }} />,
                      },
                      {
                        url: '/create',
                        label: 'Create',
                        icon: <TemplateBackstageLogo classes={{ svg: '', path: '' }} />,
                      },
                    ]}
                  />
                </Grid>
                <Grid item xs={12} md={6}>
                    <HomePageRandomJoke />
                </Grid>
              </Grid>
            </Grid>
          </Grid>
        </Content>
      </Page>
    </SearchContextProvider>
  );
};
